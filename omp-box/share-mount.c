#define _GNU_SOURCE

#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <linux/openat2.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mount.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <unistd.h>

static int complain(const char *what, const char *arg) {
	fprintf(stderr, "omp-share-mount: %s %s: %s\n", what, arg ? arg : "", strerror(errno));
	return 1;
}

static int beneath(int dirfd, const char *path, int flags, int absolute) {
	struct open_how how = {
		.flags = flags,
		.resolve = RESOLVE_NO_SYMLINKS | (absolute ? 0 : RESOLVE_BENEATH),
	};
	return syscall(SYS_openat2, dirfd, path, &how, sizeof how);
}

static int as_dir(int dirfd, const char *path, int absolute) {
	return beneath(dirfd, path, O_PATH | O_DIRECTORY | O_NOFOLLOW, absolute);
}

static int own(int fd, uid_t uid, gid_t gid) {
	struct stat st;
	if (fstat(fd, &st) < 0) return -1;
	if (st.st_uid == uid && st.st_gid == gid) return 0;
	if (fchownat(fd, "", uid, gid, AT_EMPTY_PATH) == 0) return 0;
	return -1;
}

static int descend(int *dirfd, const char *component, uid_t uid, gid_t gid, int leave) {
	int next = as_dir(*dirfd, component, 0);
	if (next < 0 && errno == ENOENT) {
		if (mkdirat(*dirfd, component, 0755) < 0 && errno != EEXIST) return -1;
		next = as_dir(*dirfd, component, 0);
	}
	if (next < 0) return -1;
	if (!leave && own(next, uid, gid) < 0) {
		close(next);
		return -1;
	}
	close(*dirfd);
	*dirfd = next;
	return 0;
}

static int mounted(int fd) {
	struct statx here, up;
	if (statx(fd, "", AT_EMPTY_PATH, STATX_MNT_ID, &here) < 0) return -1;
	int parent = openat(fd, "..", O_PATH | O_DIRECTORY);
	if (parent < 0) return -1;
	int r = statx(parent, "", AT_EMPTY_PATH, STATX_MNT_ID, &up);
	close(parent);
	if (r < 0) return -1;
	return here.stx_mnt_id != up.stx_mnt_id;
}

static int show(int fd, char *out, size_t size) {
	char proc[64];
	snprintf(proc, sizeof proc, "/proc/self/fd/%d", fd);
	ssize_t n = readlink(proc, out, size - 1);
	if (n < 0) return -1;
	out[n] = 0;
	return 0;
}

static int under_home(const char *home, const char *path) {
	int fd = as_dir(AT_FDCWD, home, 1);
	if (fd < 0) return -1;
	char *walk = strdup(path);
	if (!walk) {
		int e = errno;
		close(fd);
		errno = e;
		return -1;
	}
	char *save = NULL;
	for (char *part = strtok_r(walk, "/", &save); part; part = strtok_r(NULL, "/", &save)) {
		if (part[0] == 0 || strcmp(part, ".") == 0) continue;
		if (strcmp(part, "..") == 0) {
			close(fd);
			free(walk);
			errno = EINVAL;
			return -1;
		}
		if (descend(&fd, part, 0, 0, 1) < 0) {
			int e = errno;
			close(fd);
			free(walk);
			errno = e;
			return -1;
		}
	}
	free(walk);
	return fd;
}

static int overlay(char **argv) {
	const char *home = argv[0], *path = argv[1], *lower = argv[2], *upper = argv[3], *work = argv[4];
	int target = under_home(home, path);
	if (target < 0) return complain("open the overlay mount point", path);
	int ismounted = mounted(target);
	if (ismounted < 0) {
		int e = errno;
		close(target);
		errno = e;
		return complain("check the overlay mount point", path);
	}
	if (ismounted) {
		close(target);
		return 0;
	}
	char options[PATH_MAX * 3 + 64];
	int n = snprintf(options, sizeof options, "lowerdir=%s,upperdir=%s,workdir=%s", lower, upper, work);
	if (n < 0 || (size_t) n >= sizeof options) {
		close(target);
		errno = ENAMETOOLONG;
		return complain("overlay options", path);
	}
	char topath[64];
	snprintf(topath, sizeof topath, "/proc/self/fd/%d", target);
	if (mount("overlay", topath, "overlay", 0, options) < 0) {
		int e = errno;
		close(target);
		errno = e;
		return complain("overlay", path);
	}
	close(target);
	return 0;
}

static int apply(char **argv) {
	const char *home = argv[0], *path = argv[1], *source = argv[5];
	uid_t uid = (uid_t) strtoul(argv[2], NULL, 10);
	gid_t gid = (gid_t) strtoul(argv[3], NULL, 10);
	int ro = strcmp(argv[4], "ro") == 0;
	int absolute = path[0] == '/';
	char *walk = strdup(path);
	if (!walk) return complain("out of memory", "");

	int target;
	if (absolute) {
		target = as_dir(AT_FDCWD, "/", 1);
	} else {
		target = as_dir(AT_FDCWD, home, 1);
	}
	if (target < 0) return complain("open the user's home", absolute ? "/" : home);

	char *save = NULL;
	if (absolute) {
		while (*walk == '/') walk++;
	}
	char *next_part = strtok_r(walk, "/", &save);
	while (next_part) {
		char *part = next_part;
		while (part && (part[0] == 0 || strcmp(part, ".") == 0)) part = strtok_r(NULL, "/", &save);
		if (!part) break;
		next_part = strtok_r(NULL, "/", &save);
		while (next_part && (next_part[0] == 0 || strcmp(next_part, ".") == 0)) next_part = strtok_r(NULL, "/", &save);
		if (strcmp(part, "..") == 0) {
			close(target);
			fprintf(stderr, "omp-share-mount: %s is not a plain path\n", path);
			return 1;
		}
		if (descend(&target, part, uid, gid, absolute || next_part == NULL) < 0) {
			int e = errno;
			close(target);
			errno = e;
			return complain("descend", path);
		}
	}

	char place[PATH_MAX];
	if (show(target, place, sizeof place) < 0) return complain("name the target", path);
	int ismounted = mounted(target);
	if (ismounted < 0) return complain("check the target", path);
	if (!ismounted) {
		int from = as_dir(AT_FDCWD, source, 1);
		if (from < 0) return complain("open the share", source);
		char fromplace[64];
		snprintf(fromplace, sizeof fromplace, "/proc/self/fd/%d", from);
		char topath[64];
		snprintf(topath, sizeof topath, "/proc/self/fd/%d", target);
		if (mount(fromplace, topath, NULL, MS_BIND, NULL) < 0) {
			close(from);
			return complain("bind", path);
		}
		close(from);
		if (ro && mount(NULL, place, NULL, MS_BIND | MS_REMOUNT | MS_RDONLY, NULL) < 0) return complain("bind read-only", path);
	}
	close(target);
	printf("%s\n", place);
	return 0;
}

static int remove_place(char **argv) {
	const char *path = argv[0];
	int fd = as_dir(AT_FDCWD, path, 1);
	if (fd < 0) {
		if (errno == ENOENT) return 0;
		return complain("open", path);
	}
	int ismounted = mounted(fd);
	char place[PATH_MAX];
	int named = show(fd, place, sizeof place);
	close(fd);
	if (ismounted != 1 || named < 0) return 0;
	if (umount2(place, MNT_DETACH) < 0 && errno != EINVAL && errno != ENOENT) return complain("unmount", place);
	return 0;
}

int main(int argc, char **argv) {
	if (argc == 8 && strcmp(argv[1], "apply") == 0) return apply(argv + 2);
	if (argc == 3 && strcmp(argv[1], "remove") == 0) return remove_place(argv + 2);
	if (argc == 7 && strcmp(argv[1], "overlay") == 0) return overlay(argv + 2);
	fprintf(stderr, "usage: omp-share-mount apply HOME PATH UID GID ro|rw SOURCE | remove PATH | overlay HOME PATH LOWER UPPER WORK\n");
	return 2;
}
