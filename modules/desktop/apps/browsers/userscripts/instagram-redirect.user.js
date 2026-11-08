
// ==UserScript==
// @name Instagram Redirect
// @namespace http://tampermonkey.net/
// @icon https://github.com/D0T7/Instagram-Redirect/raw/main/inst.png
// @version 0.3
// @description	Redirect Instagram
// @author          D0T7 (https://github.com/D0T7)
// @run-at document-start
// @match *://instagram.com/*
// @match *://*.instagram.com/*

// @downloadURL https://update.greasyfork.org/scripts/448399/Instagram%20Redirect.user.js
// @updateURL https://update.greasyfork.org/scripts/448399/Instagram%20Redirect.meta.js
// ==/UserScript==

let redirectInstagram = () => {

  let url = "imginn.com"; // change to some other ig viewer if this isn't working.

  if (window.location.pathname.indexOf("/p/") == 0) {
    window.stop();
    location.hostname = url;
  } else if (window.location.pathname == "/") {
    window.stop();
    location.hostname = url;
  } else if (window.location.pathname === "/accounts/login/") {
    window.stop();
    let oldQuery = window.location.search;
    let newQuery = oldQuery.replace("?next=/", "/");
    let newURL =
      window.location.protocol + "//" + url + newQuery +
      window.location.hash;
    window.location.replace(newURL);
  } else {
    window.stop();
    let oldUrlPath = window.location.pathname;
    let newURL =
      window.location.protocol + "//" + url + oldUrlPath + window.location.search + window.location.hash;
    window.location.replace(newURL);
  }
};

redirectInstagram();