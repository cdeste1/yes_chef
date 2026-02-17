'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"assets/assets/recipes.json": "a6d224b0b5397a0dce058a885f19e458",
"assets/assets/Photos/YesChefLogo.png": "7b03fc849be28d6d0157007ead896b44",
"assets/assets/Photos/YesChefLogo_transparent.png": "a3fb588728ba3c730df5683f4441cbec",
"assets/assets/Photos/Recipes/rubeye_mushroompuree_beeftea.png": "67381436c871b1b80c48edb6c6cb4d49",
"assets/assets/Photos/Recipes/BrownButterSable_TonkaGanache.png": "686664e0825576584a135f0e6a68f6f7",
"assets/assets/Photos/Recipes/striploing_blackgarlie_redwinejus.png": "2e53c418b336e54eec33b2357a596eef",
"assets/assets/Photos/Recipes/CocoaButter_Martini.webp": "cb98712ff1b2084788678e9c27657cc1",
"assets/assets/Photos/Recipes/DeathinVenice.webp": "577c5f9a3ca6518e6f565e3adadd448d",
"assets/assets/Photos/Recipes/DuckConsomme_Soba_ShavedTruffle.png": "c1552c67cb66b6d146dc9dcdf9e6f3b1",
"assets/assets/Photos/Recipes/BuckwheatBrioche.webp": "8f7f23b6c523ac9260b2f3c922e8993d",
"assets/assets/Photos/Recipes/MaltedBarleyFlatbread_FlowerButter.jpg": "dfc610e479198b11acb1ad0084ef95fe",
"assets/assets/Photos/Recipes/caciopepe_truffleessense.png": "a05642e6e154e64237c2f35ce7194d00",
"assets/assets/Photos/Recipes/smokedChestnut_boulevardier.webp": "be0b62b6130e26f8a864964e830ceff7",
"assets/assets/Photos/Recipes/Corn-fedhen_morels_vinjaunesauce.png": "aed3c0356bd5760c94b828a87e4053f5",
"assets/assets/Photos/Recipes/LegumesJardin_Spring.jpg": "8473612b0825f74de97f58afff724fe5",
"assets/assets/Photos/Recipes/Parm_5_ages.png": "085a981e53a369341a8dca88251cd04b",
"assets/assets/Photos/Recipes/Sourdough_CarmelizedOnions.webp": "31149410c173b39e9a05f56e88f79eed",
"assets/assets/Photos/Recipes/Elderflower_Bergamot_Spritz.webp": "86336309a0acc8a7793ea0ed51c7ac77",
"assets/assets/Photos/Recipes/SaffronCitrusAmericano.webp": "9826ef543b768a94b5ce391fcb4b16dc",
"assets/assets/Photos/Recipes/BallotineBresse_Truffle_JusGras.jpg": "fcb041bbfd37a744076153a2077be925",
"assets/assets/Photos/Recipes/RoastedChicken_WildMushroom_SherryReduction.png": "3873864cee909e0b7660ed3c410b5b47",
"assets/assets/Photos/Recipes/Inception.webp": "9a17e6679d0ebc8d9dc60d9336fe9780",
"assets/assets/Photos/Recipes/poachedsalmon_cucumberspheres_dillfoam.webp": "0631263ac9dba109a8e644662f7f811b",
"assets/assets/Photos/Recipes/ToastedCoconut_RumNightcap.webp": "2374da6ba1c7192d72a4e2e467843e99",
"assets/assets/Photos/Recipes/CarmelizedFigManhatten.webp": "73b41d4201a955f94b35014f03c443dc",
"assets/assets/Photos/Recipes/SmokedShortRib_CeleriacPuree_TruffleDust.png": "fefdca1c8ac1e10e81fd89ded98e6ce0",
"assets/assets/Photos/Recipes/Pretzel_Mustard.jpg": "2845e528cc10cb3f07267ff85e650885",
"assets/assets/Photos/Recipes/LobsterTaco_SaffronTortilla_Caviar.png": "6ed69976a79415c28d85a0223a997fbb",
"assets/assets/Photos/Recipes/Cognac_Saffron_Nightcap.webp": "e36194b56b402b44c7a68bbc70277a2e",
"assets/assets/Photos/Recipes/cacaosable_caramel.webp": "d193455085d51d1dede736cf781e830c",
"assets/assets/Photos/Recipes/Saffron75.webp": "480a7b3c3fbebc9964929486e25a1434",
"assets/assets/Photos/Recipes/Agnolotti_Plin.png": "ffc3a7cfd68bfee0e21b663346369b1c",
"assets/assets/Photos/Recipes/DeconstructedChocolateChipCookieSphere.png": "9f87e3908504bf93733ee74a24997793",
"assets/assets/Photos/Recipes/Grapefruit_Campari_Snowburst.webp": "e5da861b32bcf9425be243832fe91ef8",
"assets/assets/Photos/Recipes/VegetableConsomme_EdibleFlowerRavioli.webp": "28e6be93add8a51951250a39742d5437",
"assets/assets/Photos/Recipes/negronicaviarorangegel.webp": "480b11f4ed5a65746be98d1a9ad35ddf",
"assets/assets/Photos/Recipes/BakedCamembert_Grapes_Walnuts.webp": "44c6f570f63318f2ba9591d2bca9415d",
"assets/assets/Photos/Recipes/melon_prosciuttoair_basilpearls.png": "efdefca9b528b559110724f5c5eee106",
"assets/assets/Photos/Recipes/SquidInkTagliolini_SeaUrchin_Bottarga.png": "c7b7d7503986dfbe46170b87ce2ec722",
"assets/assets/Photos/Recipes/agnolotti_lemonsauce.png": "ec21038ffce3f2d62ae1d140af2bb345",
"assets/assets/Photos/Recipes/MicroVegetablePlatter.jpg": "9e604ecab100ec65cd2d2f6ef8af4124",
"assets/assets/Photos/Recipes/BresseChicken_enVessie.webp": "79011581ffb4af954ee591535f6af50d",
"assets/assets/Photos/Recipes/GoldenOrchardSpritz.webp": "3d9a52bb404ebc4adba43d6b7ba1f8aa",
"assets/assets/Photos/Recipes/misochocolatetuile_carmalizednibs.webp": "5eed15e86ebb1ded13133c5d83217698",
"assets/assets/Photos/Recipes/ChocholateChipTuile_icecreamsandwhich.png": "58b7dcbc68c7c53d22c0cb11a6b8935f",
"assets/assets/Photos/Recipes/Lagoustine_KomboBroth_Foam.jpg": "8ac7b7ecd78834b2cb99f7de1633a14f",
"assets/assets/Photos/Recipes/burrata_tomatowatersnow_basiloil.png": "1e85f6c1191695ac50bab4d658d2542a",
"assets/assets/Photos/Recipes/PinWheelLasagna.png": "0039ec8843166376261ee8d395af5ee7",
"assets/assets/Photos/Recipes/lobstertortelinni_bisquereduction_lemonfoam.png": "4ff9ed628e294ac5326878d1fbb5d72d",
"assets/assets/Photos/Recipes/BlackTruffle_OldFashioned.webp": "c6d59be07efdfaf3b2512c88ce5f8d8f",
"assets/assets/Photos/Recipes/quinorissotto_artichoke_garlicpuree.png": "83257d922a91b163b6d61438d8e0ccd7",
"assets/assets/Photos/Recipes/corncremebrulee.webp": "ef2031519a373a804b147354d99a0f98",
"assets/assets/Photos/Recipes/TruffleMilkRolls.webp": "d12137b87f2a945c59937c41af25fc37",
"assets/assets/Photos/Recipes/WhiteTea_HoneyFizz.webp": "1b6c4731d5c5ba172ed70ce6c6aeb5bd",
"assets/assets/Photos/Recipes/CeleryGinCloud.webp": "ca9822318fc71c59fa43ed0942167060",
"assets/assets/Photos/Recipes/OxtailBarbacoa_CornEspuma_LimeGel.png": "3e83a55d9c84efc12e2d019e34e48b83",
"assets/assets/Photos/Recipes/BeefTenderloin_BoneMarrowSabayon.webp": "fff6004f1645f5de0c4ade91a6422c94",
"assets/assets/Photos/Recipes/duckcarnitas_molenegro_cocoanibdust.webp": "2d9b6fb2d2e82ec04b419d772c9aecb8",
"assets/assets/Photos/Recipes/Vanilla_Espresso_Cloud.webp": "9aa670642c82db7314bd8629bc79cbe2",
"assets/NOTICES": "3f6ba04089832d8ec49fd84951aae7ec",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/AssetManifest.bin.json": "c4e8c57db1e3b00db157b853cce69333",
"assets/fonts/MaterialIcons-Regular.otf": "2fdaae18d1f7b51f2ebc3deaf11cf5be",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "8d04e0d68420f9d97222c4407977a2ff",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"index.html": "c3aee3bc9f388c28a115bfa3087fdd0c",
"/": "c3aee3bc9f388c28a115bfa3087fdd0c",
"manifest.json": "c9a9dca1dd780e504c530e0e557db669",
"flutter_bootstrap.js": "8c71cb30fed05591fc43ac78948c26da",
"main.dart.js": "26c4b1c919697c2e1ae483310d1f6bdc",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"version.json": "d763cca0e441e58f7dfd0d1b8fc22413",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
