(function() {
  var CoffeeColorPickerDirective, module;

  CoffeeColorPickerDirective = function() {
    var directive;
    directive = {
      restrict: "A",
      link: function(scope, elm, attrs) {
        var element;
        element = angular.element(elm);
        element.coffeeColorPicker();
        return element.on('pick', function(event, color) {
          scope.$color = color;
          return scope.$apply(function() {
            return scope.$eval(attrs.coffeeColorPicker);
          });
        });
      }
    };
    return directive;
  };

  module = angular.module('coffeeColorPicker', []);

  module.directive('coffeeColorPicker', CoffeeColorPickerDirective);

}).call(this);
