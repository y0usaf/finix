// ==UserScript==
// @name        Bypass login on mature posts
// @match       *://*.artstation.com/*
// @match       *://*.deviantart.com/*
// @match       *://*.bsky.app/*
// @match       *://*.vgen.co/*
// @match       *://*.cxc.today/*
// @match       *://*.reddit.com/*
// @match       *://*.vimeo.com/*
// @match       *://*.kusowanka.com/*
// @grant       none
// @author      -
// @license      MIT
// @version     16.2
// @description Bypass login on specific websites that block access to mature content without logging in.
// @namespace Violentmonkey Scripts
// @downloadURL https://update.greasyfork.org/scripts/540384/Bypass%20login%20on%20mature%20posts.user.js
// @updateURL https://update.greasyfork.org/scripts/540384/Bypass%20login%20on%20mature%20posts.meta.js
// ==/UserScript==

(function() {
    'use strict';
    var done = false;
    function uncensor() {
        if (window.location.hostname.endsWith('artstation.com')) {
            document.querySelector('mature-content')?.remove();
            document.querySelector('.matureContent')?.remove();
            document.querySelector('.matureContent-hide')?.classList.remove('matureContent-hide');
        }
        if (window.location.hostname.endsWith('kusowanka.com')) {
          document.querySelectorAll('.blacklisted').forEach(el => { el.classList.remove('blacklisted'); });
          document.querySelector('.filter')?.classList.remove('filter');
        }
        if (window.location.hostname.endsWith('vgen.co')) {
            document.querySelectorAll('.blurContainer').forEach(el => { el.classList.remove('blurContainer'); });
            document.querySelectorAll('[class^="MatureContentWarning__MatureContentOuterContainer"]').forEach(el => el.remove());
            document.querySelectorAll('.innerMedia').forEach(el => {
              el.style.setProperty("height", "100%", "important");
              el.style.setProperty("width", "100%", "important");
            });
        }
        if (window.location.hostname.endsWith('cxc.today')) {
          document.querySelector('.q-card')?.remove();
          document.querySelector('.q-dialog__backdrop')?.remove();
          document.body.removeAttribute('class');
          //annoying 'come back later'
          document.querySelector('.blur-screen-info')?.remove();
        }
        if (window.location.hostname.endsWith('reddit.com')) {
          document.querySelector('#configured-xpromo-blocking_xpromo_nsfw_blocking_desktop')?.remove();
          document.querySelectorAll('xpromo-nsfw-blocking-container').forEach(n => n.shadowRoot?.querySelectorAll('[class*="prompt"]').forEach(el => el.remove()));
          document.querySelector('.rpl-scroll-lock')?.classList.remove('rpl-scroll-lock');
        }
        if (window.location.hostname.endsWith('bsky.app') && window.location.pathname.includes('post')) {
          async function detectURLandReplace() {

          //chose div not button because appending image inside the button makes the image gigantic, having button as the last element here would be useful if i wanted to use replaceWith below
          const element = document.querySelector('main > div:nth-child(2) > div > div > div > div:nth-child(2) > div:nth-child(2) > div:nth-child(2) > div > div:nth-child(3) > div > div:nth-child(2) > div:nth-child(2) > div > div:nth-child(2) > div > div, main > div:nth-child(2) > div > div > div > div:nth-child(2) > div:nth-child(2) > div:nth-child(2) > div > div:nth-child(3) > div > div:nth-child(2) > div:nth-child(2) > div > :is(:nth-child(2), :nth-child(3)) > div');
          if (element && element.querySelector('div > button > div > div > div > img, div > div > div > div > div > div > button > div > div > img')){
            console.log("Not NSFW. Exiting!");
            return;
          }
          if (!element && !done) {
            console.log("Element not yet loaded! Exiting!");
            return;
          } else if (!element && done) {
            console.log("Element already replaced! Exiting!");
            return;
          }

          console.log("Element: ", element);
          const pathParts = window.location.pathname.split('/');
          const idFromUrl1 = pathParts[pathParts.length - 1];
          const idFromUrl2 = pathParts[pathParts.length - 3];

          const resp = await fetch(`https://public.api.bsky.app/xrpc/app.bsky.unspecced.getPostThreadV2?anchor=at://${idFromUrl2}/app.bsky.feed.post/${idFromUrl1}&branchingFactor=1&below=10&sort=top`);
          console.log("Fetch request response body:", resp);

          const data = await resp.json();  // Parse JSON body

          const fullsize =
            data.thread[0].value.post.embed.images?.[0]?.fullsize ??
            data.thread[0].value.post.embed.media?.images?.[0]?.fullsize ??
            data.thread[0].value.post.embed.external.thumb;

          console.log("Image URL:", fullsize);

          //have this check for this variable otherwise its gonna spam infinite images and ddos the endpoint due to mutation observer detecting change
          if (done==false) {
            done = true;
          const img = document.createElement('img');
          img.src = fullsize;
          element.appendChild(img);
          console.log(img);
          }

          //set done back to false to have the image appendage above work more than once
          window.addEventListener('popstate', (event) => {
              console.log('User pressed the Back button (or Forward)!');
              done=false;
              return;
          });

          }

          detectURLandReplace();

        }
        if (window.location.hostname.endsWith('deviantart.com')) {
            if (done==false) {
                done = true;

          function replaceBackgroundWithImage(selector) {
            let element = document.querySelector(selector);
            if (!element) return;
            if (!(element.tagName === "DIV" && /^background-image\s*:\s*url/i.test(element.getAttribute("style") || ""))) {
              return;
            }


            //There are images without <figure> element
            document.querySelector('body > main > div > div > div > div > div:nth-child(2) > div > div:nth-child(2)')?.remove();
            //And with <figure> element
            document.querySelector('body > main > div > div > div > div > figure > div > div > div:nth-child(2)')?.remove();

            element.classList.remove(element.classList.item(1));


            element.style.backgroundImage = element.style.backgroundImage.replace(
            /w_\d+,h_\d+/,
            "w_800,h_800"
            );


            const imageUrl = element.style.backgroundImage.slice(4, -1).replace(/['"]/g, '');

            const img = document.createElement('img');
            img.src = imageUrl;
            img.className = element.className;
            element.replaceWith(img);
            img.parentElement.classList.remove(img.parentElement.classList.item(0));
          }

				replaceBackgroundWithImage('body > main > div > div > div > div > div:nth-child(2) > div > div > div');
				replaceBackgroundWithImage('body > main > div > div > div > div > figure > div > div > div > div');
		    }
        }
    }

    // Observe DOM changes in case elements load dynamically
    console.log(done);
    const observer = new MutationObserver(uncensor);
    observer.observe(document.body, { childList: true, subtree: true });

    if (window.location.hostname.endsWith('vimeo.com')) {
      (function () {
        let checked = false;
        const originalFetch = window.fetch;

        window.fetch = async function (...args) {
          const response = await originalFetch.apply(this, args);

          if (checked) return response;

          const url = response.url || "";
          if (/api\.vimeo\.com\/videos\/\d+/.test(url)) {
            checked = true;
            try {
              const data = await response.clone().json();
              console.log("[Vimeo check] URL:", url);
              console.log("[Vimeo check] content_rating_class =", data.content_rating_class);
              console.log("[Vimeo check] full object keys:", Object.keys(data));

              if (data.content_rating_class == "explicit") {
                const match = location.href.match(/vimeo\.com\/(\d+)/);
                if (match) {
                  console.log("[Vimeo check] Not safe → redirecting to player");
                  location.href = `https://player.vimeo.com/video/${match[1]}`;
                }
              } else {
                console.log("[Vimeo check] Rated safe → no redirect");
              }
            } catch (err) {
              console.warn("[Vimeo check] Failed to parse JSON:", err);
            }
          }

          return response;
        };
      })();
    }

})();