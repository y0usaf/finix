// Mounts the folders omp-box granted one box user, without ever trusting a path the user can change.
//
// The box grants land inside a bot's own home, which that bot owns and can rewrite at any moment: it can replace
// ~/.local with a symlink to /etc, and a root process that walks the path with mkdir/chown/mount would follow it.
// So every step here works on directory fds opened with RESOLVE_NO_SYMLINKS and never on a path: components are
// created with mkdirat on the parent fd, ownership is set through the fd, and the bind mount names the target as
// /proc/self/fd/N, which the kernel resolves to the already-opened directory. A symlink anywhere in the way is a
// refusal, never a follow, and a path that changes between the check and the mount is the same opened directory.
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

// Hands the user a folder it has to be able to write, through the fd that was opened without following anything.
// A folder that already is the user's is left alone, which keeps every pass after the first from touching it.
static int own(int fd, uid_t uid, gid_t gid) {
	struct stat st;
	if (fstat(fd, &st) < 0) return -1;
	if (st.st_uid == uid && st.st_gid == gid) return 0;
	if (fchownat(fd, "", uid, gid, AT_EMPTY_PATH) == 0) return 0;
	return -1;
}

// One component under dirfd: reuse it if it is a directory, create it if it is not there, and refuse a symlink or a
// file, which is what a bot plants in the hope that root follows it somewhere else.
static int descend(int *dirfd, const char *component, uid_t uid, gid_t gid, int leave) {
	int next = as_dir(*dirfd, component, 0);
	if (next < 0 && errno == ENOENT) {
		if (mkdirat(*dirfd, component, 0755) < 0 && errno != EEXIST) return -1;
		next = as_dir(*dirfd, component, 0);
	}
	if (next < 0) return -1;
	// The last component is the mount point itself, which the share covers, so it is left as it is: chowning it
	// would reach into a mount a previous pass made there, which is not root's to hand out.
	if (!leave && own(next, uid, gid) < 0) {
		// The folder exists and root could not chown it: refuse rather than mount into something it does not own.
		close(next);
		return -1;
	}
	close(*dirfd);
	*dirfd = next;
	return 0;
}

// Whether this directory already carries a mount of its own. Comparing device numbers is not enough: every grant
// comes out of the same share tree, so binding one folder inside another leaves both on the same device and the
// service would mount the same grant again every two seconds until the box runs out of mount slots. The mount id
// of the directory against its parent's says exactly what is wanted.
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

// apply HOME REL|PATH UID GID ro|rw SOURCE - mount SOURCE where the user sees REL under HOME (or PATH, absolute),
// creating the folders on the way as that user, and print the resolved place so it can be unmounted by name later.
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
	// Absolute paths keep their first component as what is under /; relative ones are walked from the home.
	if (absolute) {
		while (*walk == '/') walk++;
	}
	// Every component is walked before anything is mounted, so the last one is known by looking ahead.
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
		// Only a bot's own home-relative path gets its folders handed to the bot: an absolute path is a place the
		// box's own user asked for (a grant like /tmp/omp-box-checkins), and nothing on the way belongs to them.
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
		// A remount has to name the mount by path; the place came out of the fd we opened and is a mount point now,
		// so it cannot be swapped for a link underneath us the way the folders on the way here could be.
		if (ro && mount(NULL, place, NULL, MS_BIND | MS_REMOUNT | MS_RDONLY, NULL) < 0) return complain("bind read-only", path);
	}
	close(target);
	printf("%s\n", place);
	return 0;
}

// remove PATH - unmount the place a previous pass printed, but only if it still resolves without a symlink and is
// still a mount; a path a bot can no longer be trusted with is left alone rather than followed.
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
	fprintf(stderr, "usage: omp-share-mount apply HOME PATH UID GID ro|rw SOURCE | remove PATH\n");
	return 2;
}
