(function() {
  var CoffeeColorPickerDirective, module;

  CoffeeColorPickerDirective = function() {
    var directive;
    directive = {
      restrict: "A",
      link: function(scope, elm, attrs) {
        var element, options;
        element = angular.element(elm);
        if (attrs.coffeeColorPickerOptions) {
          options = scope.$eval(attrs.coffeeColorPickerOptions);
          element.coffeeColorPicker(options);
        } else {
          element.coffeeColorPicker();
        }
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
