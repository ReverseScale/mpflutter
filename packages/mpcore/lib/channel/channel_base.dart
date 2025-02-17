part of '../mpcore.dart';

bool requestingRoute = false;
String routeRequestId = '';

class MPNavigatorObserver extends NavigatorObserver {
  static final instance = MPNavigatorObserver();
  static bool doBacking = false;
  static bool initialPushed = false;

  String initialRoute = '/';
  Map initialParams = {};
  Map<int, Route> routeCache = {};
  Map<int, Size> routeViewport = {};

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings.name?.startsWith('/mp_dialog/') == true) {
      return;
    }
    routeCache[route.hashCode] = route;
    if (requestingRoute) {
      final routeData = json.encode({
        'type': 'route',
        'message': {
          'event': 'responseRoute',
          'requestId': routeRequestId,
          'routeId': route.hashCode,
        },
      });
      MPChannel.postMessage(routeData);
      requestingRoute = false;
    } else {
      if (!initialPushed && previousRoute == null) {
        initialPushed = true;
        return;
      }
      final routeData = json.encode({
        'type': 'route',
        'message': {
          'event': 'didPush',
          'routeId': route.hashCode,
          'name': route.settings.name ?? '/',
          'params': (() {
            try {
              if (!(route.settings.arguments is Map)) return null;
              json.encode(route.settings.arguments);
              return route.settings.arguments;
            } catch (e) {
              return {};
            }
          })()
        },
      });
      MPChannel.postMessage(routeData);
    }
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (doBacking) return;
    if (route.settings.name?.startsWith('/mp_dialog/') == true) {
      return;
    }
    final routeData = json.encode({
      'type': 'route',
      'message': {
        'event': 'didPop',
        'routeId': route.hashCode,
      },
    });
    MPChannel.postMessage(routeData);
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    routeCache.remove(route.hashCode);
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null && oldRoute != null) {
      routeCache[newRoute.hashCode] = newRoute;
      if (requestingRoute) {
        final routeData = json.encode({
          'type': 'route',
          'message': {
            'event': 'responseRoute',
            'requestId': routeRequestId,
            'routeId': newRoute.hashCode,
          },
        });
        MPChannel.postMessage(routeData);
        requestingRoute = false;
      } else {
        final routeData = json.encode({
          'type': 'route',
          'message': {
            'event': 'didReplace',
            'routeId': newRoute.hashCode,
            'name': newRoute.settings.name ?? '/',
            'params': (() {
              try {
                if (!(newRoute.settings.arguments is Map)) return null;
                json.encode(newRoute.settings.arguments);
                return newRoute.settings.arguments;
              } catch (e) {
                return {};
              }
            })()
          },
        });
        MPChannel.postMessage(routeData);
      }
    }
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

class MPChannelBase {
  static void handleClientMessage(msg) {
    try {
      final obj = json.decode(msg);
      if (obj['type'] == 'window_info') {
        MPChannelBase.onWindowInfo(obj['message']);
      } else if (obj['type'] == 'gesture_detector') {
        MPChannelBase.onGestureDetectorTrigger(obj['message']);
      } else if (obj['type'] == 'overlay') {
        MPChannelBase.onOverlayTrigger(obj['message']);
      } else if (obj['type'] == 'rich_text') {
        MPChannelBase.onRichTextTrigger(obj['message']);
      } else if (obj['type'] == 'scaffold') {
        MPChannelBase.onScaffoldTrigger(obj['message']);
      } else if (obj['type'] == 'decode_drawable') {
        MPChannelBase.onDecodeDrawable(obj['message']);
      } else if (obj['type'] == 'custom_paint') {
        MPChannelBase.onCustomPaint(obj['message']);
      } else if (obj['type'] == 'router') {
        MPChannelBase.onRouterTrigger(obj['message']);
      } else if (obj['type'] == 'editable_text') {
        MPChannelBase.onEditableTextTrigger(obj['message']);
      } else if (obj['type'] == 'action') {
        MPChannelBase.onActionTrigger(obj['message']);
      } else if (obj['type'] == 'mpjs') {
        mpjs.JsBridgeInvoker.instance.makeResponse(obj['message']);
      } else if (obj['type'] == 'platform_view') {
        MPChannelBase.onPlatformViewTrigger(obj['message']);
      } else if (obj['type'] == 'scroll_view') {
        MPChannelBase.onScrollViewTrigger(obj['message']);
      } else {
        MPChannelBase.onPluginMessage(obj);
      }
    } catch (e) {
      print(e);
    }
  }

  static void onWindowInfo(Map message) {
    try {
      final num devicePixelRatio = message['devicePixelRatio'];
      DeviceInfo.physicalSizeWidth =
          message['window']['width'].toDouble() * devicePixelRatio.toDouble();
      DeviceInfo.physicalSizeHeight =
          message['window']['height'].toDouble() * devicePixelRatio.toDouble();
      DeviceInfo.devicePixelRatio = devicePixelRatio.toDouble();
      DeviceInfo.windowPadding = ui.MockWindowPadding(
        left: 0.0,
        top: message['window']['padding']['top'] is num
            ? (message['window']['padding']['top'].toDouble() *
                devicePixelRatio.toDouble())
            : 0.0,
        right: 0.0,
        bottom: message['window']['padding']['bottom'] is num
            ? (message['window']['padding']['bottom'].toDouble() *
                devicePixelRatio.toDouble())
            : 0.0,
      );
      DeviceInfo.deviceSizeChangeCallback?.call();
    } catch (e) {
      print(e);
    }
  }

  static void onGestureDetectorTrigger(Map message) {
    try {
      final widget = MPCore.findTargetHashCode(message['target'])?.widget;
      if (!(widget is GestureDetector)) return;
      if (message['event'] == 'onTap') {
        widget.onTap?.call();
      } else if (message['event'] == 'onLongPress') {
        widget.onLongPress?.call();
      } else if (message['event'] == 'onLongPressStart') {
        widget.onLongPressStart?.call(LongPressStartDetails(
          globalPosition: Offset(
            (message['globalX'] as num).toDouble(),
            (message['globalY'] as num).toDouble(),
          ),
          localPosition: Offset(
            (message['localX'] as num).toDouble(),
            (message['localY'] as num).toDouble(),
          ),
        ));
      } else if (message['event'] == 'onLongPressMoveUpdate') {
        widget.onLongPressMoveUpdate?.call(LongPressMoveUpdateDetails(
          globalPosition: Offset(
            (message['globalX'] as num).toDouble(),
            (message['globalY'] as num).toDouble(),
          ),
          localPosition: Offset(
            (message['localX'] as num).toDouble(),
            (message['localY'] as num).toDouble(),
          ),
        ));
      } else if (message['event'] == 'onLongPressEnd') {
        widget.onLongPressEnd?.call(LongPressEndDetails());
      } else if (message['event'] == 'onPanStart') {
        widget.onPanStart?.call(DragStartDetails(
          globalPosition: Offset(
            (message['globalX'] as num).toDouble(),
            (message['globalY'] as num).toDouble(),
          ),
          localPosition: Offset(
            (message['localX'] as num).toDouble(),
            (message['localY'] as num).toDouble(),
          ),
        ));
      } else if (message['event'] == 'onPanUpdate') {
        widget.onPanUpdate?.call(DragUpdateDetails(
          globalPosition: Offset(
            (message['globalX'] as num).toDouble(),
            (message['globalY'] as num).toDouble(),
          ),
          localPosition: Offset(
            (message['localX'] as num).toDouble(),
            (message['localY'] as num).toDouble(),
          ),
        ));
      } else if (message['event'] == 'onPanEnd') {
        widget.onPanEnd?.call(DragEndDetails());
      }
    } catch (e) {
      print(e);
    }
  }

  static void onOverlayTrigger(Map message) {
    try {
      final element = MPCore.findTargetHashCode(message['target']);
      final widget = element?.widget;
      if (!(widget is MPOverlayScaffold)) return;
      if (message['event'] == 'onBackgroundTap') {
        widget.onBackgroundTap?.call();
      } else if (message['event'] == 'forceClose') {
        final route = ModalRoute.of(element!);
        if (route != null && route.isCurrent == true) {
          route.navigator?.pop();
        } else if (route != null && route.isActive == true) {
          route.navigator?.removeRoute(route);
        }
      }
    } catch (e) {
      print(e);
    }
  }

  static void onRichTextTrigger(Map message) {
    try {
      if (message['event'] == 'onTap') {
        final widget = MPCore.findTargetHashCode(message['target'])?.widget;
        if (!(widget is RichText)) return;
        final span = MPCore.findTargetTextSpanHashCode(
          message['subTarget'],
          element: widget.text,
        );
        if (span?.recognizer is TapGestureRecognizer) {
          (span?.recognizer as TapGestureRecognizer).onTap?.call();
        }
      } else if (message['event'] == 'onMeasured') {
        _onMeasuredText(message['data']);
      }
    } catch (e) {
      print(e);
    }
  }

  static void onEditableTextTrigger(Map message) {
    try {
      final widget = MPCore.findTargetHashCode(message['target'])?.widget;
      if (!(widget is EditableText)) return;
      if (message['event'] == 'onSubmitted') {
        widget.onSubmitted?.call(message['data']);
      } else if (message['event'] == 'onChanged' && message['data'] is String) {
        widget.controller.changeCauseByEvent = true;
        widget.controller.text = message['data'];
        widget.controller.textDirty = false;
        widget.controller.changeCauseByEvent = false;
        widget.onChanged?.call(message['data']);
      }
    } catch (e) {
      print(e);
    }
  }

  static void onScaffoldTrigger(Map message) async {
    try {
      if (message['event'] == 'onRefresh') {
        final target = scaffoldStates.firstWhere(
          (scaffoldState) =>
              scaffoldState.context.hashCode == message['target'],
        );
        await target.widget.onRefresh?.call();
        MPChannel.postMessage(json.encode({
          'type': 'scaffold',
          'message': {
            'event': 'onRefreshEnd',
            'target': message['target'],
          },
        }));
      } else if (message['event'] == 'onPageScroll') {
        final scrollTop = message['scrollTop'];
        if (scrollTop is! num) return;
        final target = scaffoldStates.firstWhere(
          (scaffoldState) =>
              scaffoldState.context.hashCode == message['target'],
        );
        target.widget.onPageScroll?.call(scrollTop.toDouble());
      } else if (message['event'] == 'onReachBottom') {
        final target = scaffoldStates.firstWhere(
          (scaffoldState) =>
              scaffoldState.context.hashCode == message['target'],
        );
        target.widget.onReachBottom?.call();
      } else if (message['event'] == 'onWechatMiniProgramShareAppMessage') {
        final target = scaffoldStates.firstWhere(
          (scaffoldState) =>
              scaffoldState.context.hashCode == message['target'],
        );
        final result =
            await target.widget.onWechatMiniProgramShareAppMessage?.call();
        MPChannel.postMessage(json.encode({
          'type': 'scaffold',
          'message': {
            'event': 'onWechatMiniProgramShareAppMessageResolve',
            'target': message['target'],
            'params': result,
          },
        }));
      }
    } catch (e) {
      print(e);
    }
  }

  static void onDecodeDrawable(Map message) {
    try {
      if (message['event'] == 'onDecode') {
        MPDrawable.receivedDecodedResult(message);
      } else if (message['event'] == 'onError') {
        MPDrawable.receivedDecodedError(message);
      }
    } catch (e) {
      print(e);
    }
  }

  static void onCustomPaint(Map message) {
    try {
      if (message['event'] == 'onFetchImageResult') {
        MPCustomPaintToImage.receivedFetchImageResult(message);
      }
    } catch (e) {
      print(e);
    }
  }

  static void onActionTrigger(Map message) {
    try {
      MPAction.onActionTrigger(message);
    } catch (e) {
      print(e);
    }
  }

  static void onPlatformViewTrigger(Map message) async {
    try {
      if (message['event'] == 'methodCall') {
        final widget = MPCore.findTargetHashCode(message['hashCode'])?.widget;
        if (!(widget is MPPlatformView)) return;
        final result = await (widget.controller
                ?.onMethodCall(message['method'], message['params']) ??
            widget.onMethodCall?.call(message['method'], message['params']));
        if (message['requireResult'] == true) {
          MPChannel.postMessage(json.encode({
            'type': 'platform_view',
            'message': {
              'event': 'methodCallCallback',
              'seqId': message['seqId'],
              'result': result,
            },
          }));
        }
      } else if (message['event'] == 'setSize') {
        final state = MPCore.findTargetHashCode(message['hashCode'])
            ?.findAncestorStateOfType<
                MPPlatformViewWithIntrinsicContentSizeState>();
        if (state == null) return;
        state.size = Size(
          (message['size']['width'] as num).toDouble(),
          (message['size']['height'] as num).toDouble(),
        );
      } else if (message['event'] == 'methodCallCallback') {
        final seqId = message['seqId'];
        if (seqId is String) {
          MPPlatformViewController.handleInvokeMethodCallback(
              seqId, message['result']);
        }
      }
    } catch (e) {
      print(e);
    }
  }

  static void onRouterTrigger(Map message) async {
    try {
      if (message['event'] == 'requestRoute') {
        while (!MPNavigatorObserver.initialPushed) {
          await Future.delayed(Duration(milliseconds: 10));
        }
        requestingRoute = true;
        final name = message['name'] as String;
        routeRequestId = message['requestId'] as String;
        final oriParams = ((message['params'] as Map?) ?? {});
        final params = {}..addAll(oriParams);
        if (message['viewport'] is Map) {
          params['\$viewportWidth'] = message['viewport']['width'];
          params['\$viewportHeight'] = message['viewport']['height'];
        }
        final root = message['root'] as bool;
        final navigator = MPNavigatorObserver.instance.navigator;
        if (navigator == null) return;
        if (root) {
          if (MPNavigatorObserver.instance.routeCache.length == 1 &&
              MPNavigatorObserver.instance.routeCache.values.first.isFirst &&
              isEqualRoute(
                name,
                oriParams,
                MPNavigatorObserver.instance.routeCache.values.first,
              )) {
            final target = MPNavigatorObserver.instance.routeCache.values.first;
            MPNavigatorObserver.instance.routeViewport[target.hashCode] = Size(
              (message['viewport']['width'] as num).toDouble(),
              (message['viewport']['height'] as num).toDouble(),
            );
            routeScaffoldStateMap[target.hashCode]?.refreshState();
            final routeData = json.encode({
              'type': 'route',
              'message': {
                'event': 'responseRoute',
                'requestId': routeRequestId,
                'routeId': target.hashCode,
              },
            });
            MPChannel.postMessage(routeData);
            requestingRoute = false;
          } else {
            MPNavigatorObserver.doBacking = true;
            navigator.popUntil((route) {
              return route.isFirst;
            });
            MPNavigatorObserver.doBacking = false;
            await navigator.pushNamed(name, arguments: params);
          }
        } else {
          await navigator.pushNamed(name, arguments: params);
        }
      } else if (message['event'] == 'updateRoute') {
        final routeId = message['routeId'];
        final target = MPNavigatorObserver.instance.routeCache[routeId];
        if (target != null) {
          MPNavigatorObserver.instance.routeViewport[routeId] = Size(
            (message['viewport']['width'] as num).toDouble(),
            (message['viewport']['height'] as num).toDouble(),
          );
          if (target.settings.arguments is Map) {
            (target.settings.arguments as Map)['\$viewportWidth'] =
                message['viewport']['width'];
            (target.settings.arguments as Map)['\$viewportHeight'] =
                message['viewport']['height'];
          }
          routeScaffoldStateMap[routeId]?.refreshState();
        }
      } else if (message['event'] == 'disposeRoute') {
        final routeId = message['routeId'];
        final navigator = MPNavigatorObserver.instance.navigator;
        if (navigator == null) return;
        final target = MPNavigatorObserver.instance.routeCache[routeId];
        if (target != null && target.isCurrent) {
          MPNavigatorObserver.doBacking = true;
          navigator.pop();
          MPNavigatorObserver.doBacking = false;
        } else if (target != null && target.isActive) {
          navigator.removeRoute(target);
        }
      } else if (message['event'] == 'popToRoute') {
        final routeId = message['routeId'];
        final navigator = MPNavigatorObserver.instance.navigator;
        if (navigator == null) return;
        MPNavigatorObserver.doBacking = true;
        navigator.popUntil((dynamic route) {
          return route.hashCode == routeId;
        });
        MPNavigatorObserver.doBacking = false;
      }
    } catch (e) {
      print(e);
    }
  }

  static void onScrollViewTrigger(Map message) async {
    try {
      if (message['event'] == 'onScroll') {
        final element = MPCore.findTargetHashCode(message['target']);
        if (element != null) {
          final renderBox = element.findRenderObject() as RenderViewport;
          ScrollUpdateNotification(
            context: element,
            metrics: FixedScrollMetrics(
              minScrollExtent: renderBox.minScrollExtent(),
              maxScrollExtent: renderBox.maxScrollExtent(),
              pixels: renderBox.axis == Axis.horizontal
                  ? (message['scrollLeft'] as num).toDouble()
                  : (message['scrollTop'] as num).toDouble(),
              viewportDimension: renderBox.size.height,
              axisDirection: AxisDirection.down,
            ),
          ).dispatch(element);
        }
      }
    } catch (e) {
      print(e);
    }
  }

  static bool isEqualRoute(String name, Map params, Route route) {
    try {
      var equal = true;
      if (name != route.settings.name) {
        equal = false;
      } else if (json.encode(params) != json.encode(route.settings.arguments)) {
        equal = false;
      }
      return equal;
    } catch (e) {
      return false;
    }
  }

  static void onPluginMessage(Map message) {
    for (final plugin in MPCore._plugins) {
      plugin.onClientMessage(message);
    }
  }
}
