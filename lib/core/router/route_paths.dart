abstract final class RoutePaths {
  static const root = '/',
      home = '/home',
      routes = '/routes',
      favorites = '/favorites',
      settings = '/settings';
  static const tracking = '/tracking/:routeId',
      analytics = '/analytics/:routeId';
  static String trackingFor(String routeId) => '/tracking/$routeId';
  static String analyticsFor(String routeId) => '/analytics/$routeId';
}
