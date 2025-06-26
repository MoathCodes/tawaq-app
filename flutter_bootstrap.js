const words = [
    'Something is happening. Please wait.',
    'Please be patient. This may take a while.',
    'While you wait, please consider that this is a good time to take a break.',
    'Please wait. This is a good time to go grab a cup of coffee.',
    'Sometimes the things that are worth waiting for take time.',
    'Please wait. This is a good time to stretch your legs.',
    'Posture check! Please wait while we load the application.',
];

const loaderWidget = `
<div style="padding-right: 32px; padding-bottom: 32px; font-smooth: always; display: flex; flex-direction: column; align-items: end">
    Loading Application...
    <div id="words" style="font-size: 16px; opacity: 0.6; font-weight: 300; text-align: right; margin-top: 4px">
    ${words[Math.floor(Math.random() * words.length)]}
    </div>
</div>`

const shadcn_flutter_config = {
    loaderWidget: loaderWidget,
    backgroundColor: null,
    foregroundColor: null,
    loaderColor: null,
    fontFamily: 'Geist Sans',
    fontSize: '24px',
    fontWeight: '400',
    mainAxisAlignment: 'end',
    crossAxisAlignment: 'end',
    externalScripts: [
        {
            src: 'https://cdn.jsdelivr.net/npm/@fontsource/geist-sans@5.0.3/400.min.css',
            type: 'stylesheet',
        },
        {
            src: 'https://cdn.jsdelivr.net/npm/@fontsource/geist-sans@5.0.3/300.min.css',
            type: 'stylesheet',
        },
    ]
};

(()=>{var U=()=>navigator.vendor==="Google Inc."||navigator.agent==="Edg/",E=()=>typeof ImageDecoder>"u"?!1:U(),W=()=>typeof Intl.v8BreakIterator<"u"&&typeof Intl.Segmenter<"u",P=()=>{let s=[0,97,115,109,1,0,0,0,1,5,1,95,1,120,0];return WebAssembly.validate(new Uint8Array(s))},p={hasImageCodecs:E(),hasChromiumBreakIterators:W(),supportsWasmGC:P(),crossOriginIsolated:window.crossOriginIsolated};function l(...s){return new URL(_(...s),document.baseURI).toString()}function _(...s){return s.filter(e=>!!e).map((e,i)=>i===0?C(e):j(C(e))).filter(e=>e.length).join("/")}function j(s){let e=0;for(;e<s.length&&s.charAt(e)==="/";)e++;return s.substring(e)}function C(s){let e=s.length;for(;e>0&&s.charAt(e-1)==="/";)e--;return s.substring(0,e)}function L(s,e){return s.canvasKitBaseUrl?s.canvasKitBaseUrl:e.engineRevision&&!e.useLocalCanvasKit?_("https://www.gstatic.com/flutter-canvaskit",e.engineRevision):"canvaskit"}var h=class{constructor(){this._scriptLoaded=!1}setTrustedTypesPolicy(e){this._ttPolicy=e}async loadEntrypoint(e){let{entrypointUrl:i=l("main.dart.js"),onEntrypointLoaded:r,nonce:t}=e||{};return this._loadJSEntrypoint(i,r,t)}async load(e,i,r,t,n){n??=o=>{o.initializeEngine(r).then(c=>c.runApp())};let{entryPointBaseUrl:a}=r;if(e.compileTarget==="dart2wasm")return this._loadWasmEntrypoint(e,i,a,n);{let o=e.mainJsPath??"main.dart.js",c=l(a,o);return this._loadJSEntrypoint(c,n,t)}}didCreateEngineInitializer(e){typeof this._didCreateEngineInitializerResolve=="function"&&(this._didCreateEngineInitializerResolve(e),this._didCreateEngineInitializerResolve=null,delete _flutter.loader.didCreateEngineInitializer),typeof this._onEntrypointLoaded=="function"&&this._onEntrypointLoaded(e)}_loadJSEntrypoint(e,i,r){let t=typeof i=="function";if(!this._scriptLoaded){this._scriptLoaded=!0;let n=this._createScriptTag(e,r);if(t)console.debug("Injecting <script> tag. Using callback."),this._onEntrypointLoaded=i,document.head.append(n);else return new Promise((a,o)=>{console.debug("Injecting <script> tag. Using Promises. Use the callback approach instead!"),this._didCreateEngineInitializerResolve=a,n.addEventListener("error",o),document.head.append(n)})}}async _loadWasmEntrypoint(e,i,r,t){if(!this._scriptLoaded){this._scriptLoaded=!0,this._onEntrypointLoaded=t;let{mainWasmPath:n,jsSupportRuntimePath:a}=e,o=l(r,n),c=l(r,a);this._ttPolicy!=null&&(c=this._ttPolicy.createScriptURL(c));let d=(await import(c)).compileStreaming(fetch(o)),w;e.renderer==="skwasm"?w=(async()=>{let f=await i.skwasm;return window._flutter_skwasmInstance=f,{skwasm:f.wasmExports,skwasmWrapper:f,ffi:{memory:f.wasmMemory}}})():w=Promise.resolve({}),await(await(await d).instantiate(await w)).invokeMain()}}_createScriptTag(e,i){let r=document.createElement("script");r.type="application/javascript",i&&(r.nonce=i);let t=e;return this._ttPolicy!=null&&(t=this._ttPolicy.createScriptURL(e)),r.src=t,r}};async function T(s,e,i){if(e<0)return s;let r,t=new Promise((n,a)=>{r=setTimeout(()=>{a(new Error(`${i} took more than ${e}ms to resolve. Moving on.`,{cause:T}))},e)});return Promise.race([s,t]).finally(()=>{clearTimeout(r)})}var g=class{setTrustedTypesPolicy(e){this._ttPolicy=e}loadServiceWorker(e){if(!e)return console.debug("Null serviceWorker configuration. Skipping."),Promise.resolve();if(!("serviceWorker"in navigator)){let o="Service Worker API unavailable.";return window.isSecureContext||(o+=`
The current context is NOT secure.`,o+=`
Read more: https://developer.mozilla.org/en-US/docs/Web/Security/Secure_Contexts`),Promise.reject(new Error(o))}let{serviceWorkerVersion:i,serviceWorkerUrl:r=l(`flutter_service_worker.js?v=${i}`),timeoutMillis:t=4e3}=e,n=r;this._ttPolicy!=null&&(n=this._ttPolicy.createScriptURL(n));let a=navigator.serviceWorker.register(n).then(o=>this._getNewServiceWorker(o,i)).then(this._waitForServiceWorkerActivation);return T(a,t,"prepareServiceWorker")}async _getNewServiceWorker(e,i){if(!e.active&&(e.installing||e.waiting))return console.debug("Installing/Activating first service worker."),e.installing||e.waiting;if(e.active.scriptURL.endsWith(i))return console.debug("Loading from existing service worker."),e.active;{let r=await e.update();return console.debug("Updating service worker."),r.installing||r.waiting||r.active}}async _waitForServiceWorkerActivation(e){if(!e||e.state==="activated")if(e){console.debug("Service worker already active.");return}else throw new Error("Cannot activate a null service worker!");return new Promise((i,r)=>{e.addEventListener("statechange",()=>{e.state==="activated"&&(console.debug("Activated new service worker."),i())})})}};var y=class{constructor(e,i="flutter-js"){let r=e||[/\.js$/,/\.mjs$/];window.trustedTypes&&(this.policy=trustedTypes.createPolicy(i,{createScriptURL:function(t){if(t.startsWith("blob:"))return t;let n=new URL(t,window.location),a=n.pathname.split("/").pop();if(r.some(c=>c.test(a)))return n.toString();console.error("URL rejected by TrustedTypes policy",i,":",t,"(download prevented)")}}))}};var k=s=>{let e=WebAssembly.compileStreaming(fetch(s));return(i,r)=>((async()=>{let t=await e,n=await WebAssembly.instantiate(t,i);r(n,t)})(),{})};var I=(s,e,i,r)=>(window.flutterCanvasKitLoaded=(async()=>{if(window.flutterCanvasKit)return window.flutterCanvasKit;let t=i.hasChromiumBreakIterators&&i.hasImageCodecs;if(!t&&e.canvasKitVariant=="chromium")throw"Chromium CanvasKit variant specifically requested, but unsupported in this browser";let n=t&&e.canvasKitVariant!=="full",a=r;n&&(a=l(a,"chromium"));let o=l(a,"canvaskit.js");s.flutterTT.policy&&(o=s.flutterTT.policy.createScriptURL(o));let c=k(l(a,"canvaskit.wasm")),u=await import(o);return window.flutterCanvasKit=await u.default({instantiateWasm:c}),window.flutterCanvasKit})(),window.flutterCanvasKitLoaded);var b=async(s,e,i,r)=>{let t=l(r,"skwasm.js"),n=t;s.flutterTT.policy&&(n=s.flutterTT.policy.createScriptURL(n));let a=k(l(r,"skwasm.wasm"));return await(await import(n)).default({skwasmSingleThreaded:!i.crossOriginIsolated||e.forceSingleThreadedSkwasm,instantiateWasm:a,locateFile:(c,u)=>{if(c.endsWith(".ww.js")){let d=l(r,c);return URL.createObjectURL(new Blob([`
"use strict";

let eventListener;
eventListener = (message) => {
    const pendingMessages = [];
    const data = message.data;
    data["instantiateWasm"] = (info,receiveInstance) => {
        const instance = new WebAssembly.Instance(data["wasm"], info);
        return receiveInstance(instance, data["wasm"])
    };
    import(data.js).then(async (skwasm) => {
        await skwasm.default(data);

        removeEventListener("message", eventListener);
        for (const message of pendingMessages) {
            dispatchEvent(message);
        }
    });
    removeEventListener("message", eventListener);
    eventListener = (message) => {

        pendingMessages.push(message);
    };

    addEventListener("message", eventListener);
};
addEventListener("message", eventListener);
`],{type:"application/javascript"}))}return url},mainScriptUrlOrBlob:t})};var S=class{async loadEntrypoint(e){let{serviceWorker:i,...r}=e||{},t=new y,n=new g;n.setTrustedTypesPolicy(t.policy),await n.loadServiceWorker(i).catch(o=>{console.warn("Exception while loading service worker:",o)});let a=new h;return a.setTrustedTypesPolicy(t.policy),this.didCreateEngineInitializer=a.didCreateEngineInitializer.bind(a),a.loadEntrypoint(r)}async load({serviceWorkerSettings:e,onEntrypointLoaded:i,nonce:r,config:t}={}){t??={};let n=_flutter.buildConfig;if(!n)throw"FlutterLoader.load requires _flutter.buildConfig to be set";let a=m=>{switch(m){case"skwasm":return p.hasChromiumBreakIterators&&p.hasImageCodecs&&p.supportsWasmGC;default:return!0}},o=(m,f)=>m.renderer==f,c=m=>m.compileTarget==="dart2wasm"&&!p.supportsWasmGC||t.renderer&&!o(m,t.renderer)?!1:a(m.renderer),u=n.builds.find(c);if(!u)throw"FlutterLoader could not find a build compatible with configuration and environment.";let d={};d.flutterTT=new y,e&&(d.serviceWorkerLoader=new g,d.serviceWorkerLoader.setTrustedTypesPolicy(d.flutterTT.policy),await d.serviceWorkerLoader.loadServiceWorker(e).catch(m=>{console.warn("Exception while loading service worker:",m)}));let w=L(t,n);u.renderer==="canvaskit"?d.canvasKit=I(d,t,p,w):u.renderer==="skwasm"&&(d.skwasm=b(d,t,p,w));let v=new h;return v.setTrustedTypesPolicy(d.flutterTT.policy),this.didCreateEngineInitializer=v.didCreateEngineInitializer.bind(v),v.load(u,d,t,r,i)}};window._flutter||(window._flutter={});window._flutter.loader||(window._flutter.loader=new S);})();
//# sourceMappingURL=flutter.js.map

if (!window._flutter) {
  window._flutter = {};
}
_flutter.buildConfig = {"engineRevision":"8cd19e509d6bece8ccd74aef027c4ca947363095","builds":[{"compileTarget":"dart2wasm","renderer":"skwasm","mainWasmPath":"main.dart.wasm","jsSupportRuntimePath":"main.dart.mjs"},{"compileTarget":"dart2js","renderer":"canvaskit","mainJsPath":"main.dart.js"}]};


class ShadcnAppConfig {
    background;
    foreground;
    fontFamily;
    fontSize;
    fontWeight;
    mainAxisAlignment;
    crossAxisAlignment;
    loaderWidget;
    loaderColor;
    externalScripts;

    constructor({ background, foreground, fontFamily, fontSize, fontWeight, mainAxisAlignment, crossAxisAlignment, loaderWidget, loaderColor, externalScripts }) {
        this.background = background;
        this.foreground = foreground;
        this.fontFamily = fontFamily;
        this.fontSize = fontSize;
        this.fontWeight = fontWeight;
        this.mainAxisAlignment = mainAxisAlignment;
        this.crossAxisAlignment = crossAxisAlignment;
        this.loaderWidget = loaderWidget;
        this.loaderColor = loaderColor;
        this.externalScripts = externalScripts;

        if (this.background == null) {
            this.background = localStorage.getItem('shadcn_flutter.background') || '#09090b';
        }
        if (this.foreground == null) {
            this.foreground = localStorage.getItem('shadcn_flutter.foreground') || '#ffffff';
        }
        if (this.loaderColor == null) {
            this.loaderColor = localStorage.getItem('shadcn_flutter.primary') || '#3c83f6';
        }
    }
}

class ShadcnAppThemeChangedEvent extends CustomEvent {
    constructor(theme) {
        super('shadcn_flutter_theme_changed', { detail: theme });
    }
}

class ShadcnAppTheme {
    background;
    foreground;
    primary;

    constructor(background, foreground, primary) {
        this.background = background;
        this.foreground = foreground;
        this.primary = primary;
    }
}

class ShadcnApp {
    config;

    constructor(config) {
        this.config = config;
    }

    loadApp() {
        window.addEventListener('shadcn_flutter_app_ready', this.onAppReady);
        window.addEventListener('shadcn_flutter_theme_changed', this.onThemeChanged);
        this.#initializeDocument();
        let externalScriptIndex = 0;
        this.#loadExternalScripts(externalScriptIndex, () => {
            _flutter.loader.load({
                onEntrypointLoaded: async function(engineInitializer) {
                    const appRunner = await engineInitializer.initializeEngine();
                    await appRunner.runApp();
                }
            });
        });
    }

    #loadExternalScripts(index, onDone) {
        if (index >= this.config.externalScripts.length) {
            onDone();
            return;
        }
        this.#loadScriptDynamically(this.config.externalScripts[index], () => {
            this.#loadExternalScripts(index + 1, onDone);
        });
    }

    #createStyleSheet(css) {
        const style = document.createElement('style');
        style.type = 'text/css';
        style.appendChild(document.createTextNode(css));
        document.head.appendChild(style);
    }

    #loadScriptDynamically(src, callback) {
        if (typeof src === 'string') {
            src = { src: src, type: 'script' };
        }
        if (src.type === 'script') {
            const script = document.createElement('script');
            script.src = src.src;
            script.onload = callback;
            document.body.appendChild(script);
        } else if (src.type === 'module') {
            const script = document.createElement('script');
            script.type = 'module';
            script.src = src.src;
            script.onload = callback;
            document.body.appendChild(script);
        } else if (src.type === 'stylesheet') {
            const link = document.createElement('link');
            link.rel = 'stylesheet';
            link.href = src.src;
            link.onload = callback;
            document.head.appendChild(link);
        } else {
            throw new Error('Unknown type of file to load: ' + src);
        }
    }

    #initializeDocument() {
        const loaderStyle = `
            display: flex;
            justify-content: ${this.config.mainAxisAlignment};
            align-items: ${this.config.crossAxisAlignment};
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background-color: ${this.config.background};
            color: ${this.config.foreground};
            z-index: 9998;
            font-family: ${this.config.fontFamily};
            font-size: ${this.config.fontSize};
            font-weight: ${this.config.fontWeight};
            text-align: center;
            transition: opacity 0.5s;
            opacity: 1;
            pointer-events: initial;
        `;

        const loaderBarCss = `
        .loader {
          height: 7px;
          background: repeating-linear-gradient(-45deg,${this.config.loaderColor} 0 15px,#000 0 20px) left/200% 100%;
          animation: l3 20s infinite linear;
          position: fixed;
          top: 0;
          left: 0;
          right: 0;
          z-index: 9999;
        }
        @keyframes l3 {
            100% {background-position:right}
        }`;

        const loaderDiv = document.createElement('div');
        loaderDiv.style.cssText = loaderStyle;
        loaderDiv.innerHTML = this.config.loaderWidget;

        document.body.appendChild(loaderDiv);

        document.body.style.backgroundColor = this.config.background;

        const loaderBarDiv = document.createElement('div');
        loaderBarDiv.className = 'loader';
        loaderDiv.appendChild(loaderBarDiv);

        this.#createStyleSheet(loaderBarCss);
    }

    onAppReady() {
        const loaderDiv = document.querySelector('div');
        loaderDiv.style.opacity = 0;
        loaderDiv.style.pointerEvents = 'none';
    }

    onThemeChanged(event) {
        let theme = event.detail;
        let background = theme['background'];
        let foreground = theme['foreground'];
        let primary = theme['primary'];
        localStorage.setItem('shadcn_flutter.background', background);
        localStorage.setItem('shadcn_flutter.foreground', foreground);
        localStorage.setItem('shadcn_flutter.primary', primary);
    }
}

globalThis.ShadcnApp = ShadcnApp;
globalThis.ShadcnAppConfig = ShadcnAppConfig;
globalThis.ShadcnAppThemeChangedEvent = ShadcnAppThemeChangedEvent;
globalThis.ShadcnAppTheme = ShadcnAppTheme;

const shadcn_flutter = new ShadcnApp(new ShadcnAppConfig(shadcn_flutter_config));
shadcn_flutter.loadApp();