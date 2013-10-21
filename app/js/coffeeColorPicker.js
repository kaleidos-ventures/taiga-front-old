(function() {
  var $, CoffeeColorPicker, picker;

  CoffeeColorPicker = (function() {
    function CoffeeColorPicker(el, options) {
      this.settings = {
        color: {
          hue: 180,
          sat: 50,
          lit: 50
        },
        freezeTime: 1000
      };
      this.settings = $.extend({}, this.settings, options);
      this.el = el;
      this._rect = el[0].getBoundingClientRect();
      this._color = this.settings.color;
      this._setColor(this._color.hue, this._color.sat, this._color.lit);
    }

    CoffeeColorPicker.prototype.refresh = function() {
      return this._rect = this.el[0].getBoundingClientRect();
    };

    CoffeeColorPicker.prototype._onMouseMove = function(event) {
      if (this.await && this.await > new Date()) {
        return;
      }
      this.await = null;
      return this._move(event.pageY, event.pageX);
    };

    CoffeeColorPicker.prototype._onMouseWheel = function(event) {
      var delta, sat;
      event.preventDefault();
      delta = event.originalEvent.wheelDelta;
      delta += this._prev || 0;
      if (-500 > delta || 500 < delta) {
        return;
      }
      sat = delta + 500;
      this._setColor(this._color.hue, sat / 1000 * 100, this._color.lit);
      return this._prev = delta;
    };

    CoffeeColorPicker.prototype._onClick = function(event) {
      var pickedColor;
      event.preventDefault();
      this.await = this.settings.freezeTime + new Date().getTime();
      pickedColor = $.Color($(event.target), 'background').toHexString(0);
      return this.el.trigger('pick', pickedColor);
    };

    CoffeeColorPicker.prototype._bindEvents = function() {
      var _this = this;
      this.el.on("mousemove", function(event) {
        return _this._onMouseMove(event);
      });
      this.el.on("mousewheel", function(event) {
        return _this._onMouseWheel(event);
      });
      return this.el.on("click", function(event) {
        return _this._onClick(event);
      });
    };

    CoffeeColorPicker.prototype._unbindEvents = function() {
      this.el.off("mousemove");
      this.el.off("mousewheel");
      return this.el.off("click");
    };

    CoffeeColorPicker.prototype._setColor = function(hue, sat, lit) {
      this.el.css("background", "hsla(" + hue + ", " + sat + "%, " + lit + "%, 1)");
      return this._color = {
        hue: hue,
        sat: sat,
        lit: lit
      };
    };

    CoffeeColorPicker.prototype._move = function(y, x) {
      y = Math.max(0, y - this._rect.top);
      x = Math.max(0, x - this._rect.left);
      y /= this._rect.height;
      x /= this._rect.width;
      return this._setColor(x * 360, this._color.sat, y * 100);
    };

    return CoffeeColorPicker;

  })();

  $ = window.jQuery || window.Zepto;

  picker = function(el, options) {
    el = $(el);
    if (el.data("coffeeColorPicker") === void 0) {
      picker = new CoffeeColorPicker(el, options);
      picker._bindEvents();
      return picker;
    }
    return el.data("coffeeColorPicker");
  };

  $.fn.coffeeColorPicker = function(options) {
    return picker(this, options);
  };

}).call(this);
