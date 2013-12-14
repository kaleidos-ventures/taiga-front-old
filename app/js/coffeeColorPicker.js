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
      this.settings = $.extend(true, {}, this.settings, options);
      this.el = el;
      this.el.data("coffeeColorPicker", this);
      this._rect = el[0].getBoundingClientRect();
      this._color = this.settings.color;
      this._setColor(this._color.hue, this._color.sat, this._color.lit);
      this._bindEvents();
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
      delta = event.originalEvent.detail ? event.originalEvent.detail * (-120) : event.originalEvent.wheelDelta;
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
      pickedColor = $.Color($(event.target), 'background-color').toHexString(0);
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
      this.el.on("DOMMouseScroll", function(event) {
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
      this.el.css("background-color", "hsla(" + hue + ", " + sat + "%, " + lit + "%, 1)");
      return this._color = {
        hue: hue,
        sat: sat,
        lit: lit
      };
    };

    CoffeeColorPicker.prototype._move = function(y, x) {
      var x_offset, y_offset;
      if (this._rect.top === 0 || this._rect.left === 0) {
        this.refresh();
      }
      y_offset = $(document).scrollTop();
      x_offset = $(document).scrollLeft();
      y = Math.max(0, y - (this._rect.top + y_offset));
      x = Math.max(0, x - (this._rect.left + x_offset));
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
      return new CoffeeColorPicker(el, options);
    }
    return el.data("coffeeColorPicker");
  };

  $.fn.coffeeColorPicker = function(options) {
    return picker(this, options);
  };

}).call(this);
