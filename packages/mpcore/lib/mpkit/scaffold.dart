part of 'mpkit.dart';

final List<MPScaffoldState> scaffoldStates = [];
final Map<int, MPScaffoldState> routeScaffoldStateMap = {};

class MPScaffold extends StatefulWidget {
  final String? name;
  final Color? appBarColor;
  final Color? appBarTintColor;
  final Widget? body;
  final Function? onRefresh;
  final Function(double)? onPageScroll;
  final Future<Map> Function()? onWechatMiniProgramShareAppMessage;
  final Function? onReachBottom;
  final PreferredSizeWidget? appBar;
  final Widget? bottomBar;
  final bool? bottomBarWithSafeArea;
  final Color? bottomBarSafeAreaColor;
  final Widget? floatingBody;
  final Color? backgroundColor;

  MPScaffold({
    this.name,
    this.appBarColor,
    this.appBarTintColor,
    this.body,
    this.onRefresh,
    this.onPageScroll,
    this.onWechatMiniProgramShareAppMessage,
    this.onReachBottom,
    this.appBar,
    this.bottomBar,
    this.bottomBarWithSafeArea,
    this.bottomBarSafeAreaColor,
    this.floatingBody,
    this.backgroundColor,
  });

  @override
  MPScaffoldState createState() => MPScaffoldState();
}

class MPScaffoldState extends State<MPScaffold> {
  final bodyKey = GlobalKey();
  final appBarKey = GlobalKey();
  final bottomBarKey = GlobalKey();
  final floatingBodyKey = GlobalKey();

  @override
  void dispose() {
    scaffoldStates.remove(this);
    routeScaffoldStateMap.removeWhere((key, value) => value == this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    scaffoldStates.add(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      routeScaffoldStateMap[route.hashCode] = this;
    }
  }

  void refreshState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).size.width < 10 ||
        MediaQuery.of(context).size.height < 10) {
      return Container();
    }
    final mainTabBar = context
        .findAncestorStateOfType<MPMainTabViewState>()
        ?.renderTabBar(context);
    Widget child = Stack(
      children: [
        Positioned.fill(
          child: Column(
            children: [
              widget.appBar != null
                  ? MPScaffoldAppBar(key: appBarKey, child: widget.appBar)
                  : Container(),
              widget.body != null
                  ? Expanded(
                      child: MPScaffoldBody(
                        key: bodyKey,
                        child: Container(
                          color: widget.backgroundColor,
                          child: widget.body,
                        ),
                        appBarHeight: widget.appBar != null
                            ? widget.appBar?.preferredSize.height
                            : null,
                      ),
                    )
                  : Expanded(child: Container()),
              mainTabBar != null || widget.bottomBar != null
                  ? MPScaffoldBottomBar(
                      key: bottomBarKey, child: mainTabBar ?? widget.bottomBar)
                  : Container(),
            ],
          ),
        ),
        widget.floatingBody != null
            ? MPScaffoldFloatingBody(
                key: floatingBodyKey, child: widget.floatingBody)
            : Container(),
      ],
    );
    final app = context.findAncestorWidgetOfExactType<MPApp>();
    var mediaQuery = MediaQuery.of(context);
    final route = ModalRoute.of(context);
    if (route != null) {
      final routeArguments = ModalRoute.of(context)?.settings.arguments;
      if (routeArguments is Map &&
          routeArguments.containsKey('\$viewportWidth') &&
          routeArguments.containsKey('\$viewportHeight')) {
        mediaQuery = mediaQuery.copyWith(
          size: Size(
            (routeArguments['\$viewportWidth'] as num).toDouble(),
            (routeArguments['\$viewportHeight'] as num).toDouble(),
          ),
        );
        child = MediaQuery(
          data: mediaQuery,
          child: child,
        );
      } else {
        final routeViewport =
            MPNavigatorObserver.instance.routeViewport[route.hashCode];
        if (routeViewport != null) {
          mediaQuery = mediaQuery.copyWith(size: routeViewport);
          child = MediaQuery(
            data: mediaQuery,
            child: child,
          );
        }
      }
    }
    if (app != null && app.maxWidth != null) {
      if (mediaQuery.size.width > app.maxWidth!) {
        mediaQuery = mediaQuery.copyWith(
          size: Size(app.maxWidth!, mediaQuery.size.height),
        );
        child = MediaQuery(
          data: mediaQuery,
          child: child,
        );
      }
    }
    child = Align(
      alignment: Alignment.topLeft,
      child: Container(
        width: mediaQuery.size.width,
        height: mediaQuery.size.height,
        child: child,
      ),
    );
    return child;
  }
}

class MPOverlayScaffold extends MPScaffold {
  final bool? barrierDismissible;
  final Function? onBackgroundTap;
  final ModalRoute? parentRoute;

  MPOverlayScaffold({
    Widget? body,
    Color? backgroundColor,
    this.barrierDismissible,
    this.onBackgroundTap,
    this.parentRoute,
  }) : super(body: body, backgroundColor: backgroundColor);
}

class MPScaffoldBody extends StatelessWidget {
  final Widget? child;
  final double? appBarHeight;

  MPScaffoldBody({
    Key? key,
    this.child,
    this.appBarHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return child ?? Container();
  }
}

class MPScaffoldAppBar extends StatelessWidget {
  final PreferredSizeWidget? child;

  MPScaffoldAppBar({
    Key? key,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (child == null) {
      return Container();
    }
    return Container(
      constraints:
          BoxConstraints.tightFor(width: MediaQuery.of(context).size.width),
      child: child,
    );
  }
}

class MPScaffoldBottomBar extends StatelessWidget {
  final Widget? child;

  MPScaffoldBottomBar({
    Key? key,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (child == null) {
      return Container();
    }
    return Container(
      constraints:
          BoxConstraints.tightFor(width: MediaQuery.of(context).size.width),
      child: child,
    );
  }
}

class MPScaffoldFloatingBody extends StatelessWidget {
  final Widget? child;

  MPScaffoldFloatingBody({
    Key? key,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return child ?? Container();
  }
}
