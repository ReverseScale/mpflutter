declare var getCurrentPages: any;
declare var require: any;

import { Engine } from "./engine";
import { MPEnv, PlatformType } from "./env";
import { Page } from "./page";
import { Router } from "./router";
import { TextMeasurer } from "./text_measurer";
import EventEmitter from "eventemitter3";

const kboneConfig = {
  router: {},
  runtime: {
    subpackagesMap: {},
    tabBarMap: {},
    usingComponents: {},
  },
  pages: {
    index: {},
  },
  redirect: {},
  optimization: {
    domSubTreeLevel: 10,
    elementMultiplexing: true,
    textMultiplexing: true,
    commentMultiplexing: true,
    domExtendMultiplexing: true,
    styleValueReduce: 5000,
    attrValueReduce: 5000,
  },
};

export class WXApp {
  router: WXRouter = new WXRouter(this.engine);

  constructor(readonly indexPage: string, readonly engine: Engine) {
    engine.app = this;
  }
}

export const WXPage = function (
  options: { route: string; params: any } | undefined,
  selector: string = "#vdom",
  app: WXApp = MPEnv.platformGlobal().app
) {
  if (!(__MP_TARGET_WEAPP__ || __MP_TARGET_SWANAPP__)) return;
  return {
    data: {
      pageMeta: {
        naviBar: {},
      },
    },
    kboneRender: undefined as any,
    kboneDocument: undefined as any,
    kbonePageId: undefined as any,
    prepare() {
      const mpRes = this.kboneRender.createPage((this as any).route, kboneConfig);
      this.kbonePageId = mpRes.pageId;
      const window = mpRes.window;
      this.kboneDocument = mpRes.document;
      this.kboneDocument.window = window;
      window.$$createSelectorQuery = () => MPEnv.platformScope.createSelectorQuery().in(this);
      window.$$createIntersectionObserver = (options: any) =>
        MPEnv.platformScope.createIntersectionObserver(this, options);
      (this as any).setData({
        pageId: this.kbonePageId,
      });
    },
    onLoad(pageOptions: any) {
      this.prepare();
      const document = this.kboneDocument;
      const documentTm = this.kboneDocument;
      TextMeasurer.activeTextMeasureDocument = documentTm;
      Router.clearBeingPushTimeout();
      Router.beingPush = false;
      const basePath = (() => {
        let c = app.indexPage.split("/");
        c.pop();
        return c.join("/");
      })();
      let finalOptions = options;
      if (!options || pageOptions.route) {
        let params = { ...pageOptions };
        delete params["route"];
        if (pageOptions.route) {
          finalOptions = { route: pageOptions.route, params: params };
        } else {
          finalOptions = {
            route: (this as any).route.replace(basePath, ""),
            params: params,
          };
          if (finalOptions.route === "/index") {
            finalOptions.route = "/";
          }
        }
      }
      if (finalOptions?.route) {
        finalOptions.route = decodeURIComponent(finalOptions.route);
        finalOptions.params = { ...pageOptions };
      }

      (this as any).mpPage = new Page(document.body, app.engine, finalOptions, document);
      (this as any).mpPage.miniProgramPage = this;
      (this as any).mpPage.isFirst = getCurrentPages().length === 1;
    },
    onUnload() {
      if ((this as any).mpPage.viewId) {
        app.router.disposeRoute((this as any).mpPage.viewId);
      }
    },
    onShow() {
      TextMeasurer.activeTextMeasureDocument =
        this.kboneDocument ?? (this as any).selectComponent(selector + "_tm").miniDom.document;
      Router.clearBeingPushTimeout();
      Router.beingPush = false;
    },
    onPullDownRefresh() {
      (this as any).mpPage.onRefresh().then((it: any) => {
        MPEnv.platformScope.stopPullDownRefresh();
      });
    },
    onShareAppMessage() {
      return {
        promise: (this as any).mpPage.onWechatMiniProgramShareAppMessage(),
      };
    },
    onReachBottom() {
      (this as any).mpPage.onReachBottom();
    },
    onPageScroll(res: any) {
      (this as any).mpPage.onPageScroll(res.scrollTop);
      this.kboneDocument.window.scrollY = res.scrollTop;
      this.kboneDocument.window.scrollY = res.scrollTop;
      this.kboneDocument.window.scrollY = res.scrollTop;
      this.kboneDocument.window.$$trigger("scroll", res.scrollTop);
    },
  };
};

class WXRouter extends Router {
  encodeRelativePath(name: string, params?: any): string {
    let searchParams: string[] = [];
    if (params) {
      for (const key in params) {
        searchParams.push(`${key}=${encodeURIComponent(params[key])}`);
      }
    }
    if (searchParams.length > 0) {
      return `${name}?${searchParams.join("&")}`;
    } else {
      return `${name}`;
    }
  }

  encodeIndexPath(name: string, params?: any): string {
    let searchParams: string[] = [];
    if (params) {
      for (const key in params) {
        searchParams.push(`${key}=${encodeURIComponent(params[key])}`);
      }
    }
    const namePath = name.indexOf("?") >= 0 ? name.split("?")[0] : name;
    const paramPath = name.indexOf("?") >= 0 ? name.substr(name.indexOf("?")) : "";
    if (searchParams.length > 0) {
      return `/${(this.engine.app as WXApp).indexPage}?route=${encodeURI(namePath)}${encodeURIComponent(
        paramPath
      )}&${searchParams.join("&")}`;
    } else {
      return `/${(this.engine.app as WXApp).indexPage}?route=${encodeURI(namePath)}${encodeURIComponent(paramPath)}`;
    }
  }

  didPush(message: any) {
    Router.clearBeingPushTimeout();
    Router.beingPush = true;
    const routeId = message.routeId;
    this.thePushingRouteId = routeId;
    const name = message.name;
    MPEnv.platformScope.navigateTo({
      url: this.encodeRelativePath(name, message.params),
      fail: () => {
        MPEnv.platformScope.navigateTo({
          url: this.encodeIndexPath(name, message.params),
        });
      },
    });
    Router.beingPushTimeout = setTimeout(() => {
      Router.beingPush = false;
    }, 1000);
  }

  didReplace(message: any) {
    Router.clearBeingPushTimeout();
    Router.beingPush = true;
    const routeId = message.routeId;
    this.thePushingRouteId = routeId;
    const name = message.name;
    MPEnv.platformScope.redirectTo({
      url: this.encodeRelativePath(name, message.params),
      fail: () => {
        MPEnv.platformScope.redirectTo({
          url: this.encodeIndexPath(name, message.params),
        });
      },
    });
    Router.beingPushTimeout = setTimeout(() => {
      Router.beingPush = false;
    }, 1000);
  }

  async didPop() {
    if (Router.beingPush) {
      await this.delayPop();
    }
    Router.clearBeingPushTimeout();
    Router.beingPush = true;
    MPEnv.platformScope.navigateBack();
    Router.beingPushTimeout = setTimeout(() => {
      Router.beingPush = false;
    }, 1000);
  }

  delayPop() {
    if (
      __MP_TARGET_WEAPP__ &&
      (MPEnv.platformScope.getSystemInfoSync().platform === "ios" ||
        MPEnv.platformScope.getSystemInfoSync().platform === "windows" ||
        MPEnv.platformScope.getSystemInfoSync().platform === "mac")
    ) {
      return new Promise((res) => {
        setTimeout(() => {
          res(null);
        }, 500);
      });
    }
  }
}
