/*! checksley - v0.1.0 - 2013-07-15 */
(function() {
  var Checksley, Field, FieldMultiple, Form, checksley, defaults, formatMesssage, messages, toInt, validators, _checksley,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  defaults = {
    inputs: 'input, textarea, select',
    excluded: 'input[type=hidden], input[type=file], :disabled',
    focus: 'first',
    validationMinlength: 3,
    validateIfUnchanged: false,
    interceptSubmit: true,
    messages: {},
    validators: {},
    showErrors: true,
    errorClass: "checksley-error",
    successClass: "checksley-ok",
    validatedClass: "checksley-validated",
    onlyOneErrorElement: false,
    containerClass: "checksley-error-list",
    containerGlobalSearch: false,
    containerPreferenceSelector: ".errors-box",
    errors: {
      classHandler: function(element, isRadioOrCheckbox) {
        return element;
      },
      container: function(element, isRadioOrCheckbox) {
        return element.parent();
      },
      errorsWrapper: "<ul />",
      errorElem: "<li />"
    },
    listeners: {
      onFieldValidate: function(element, field) {
        return false;
      },
      onFormSubmit: function(ok, event, form) {},
      onFieldError: function(element, constraints, field) {},
      onFieldSuccess: function(element, constraints, field) {}
    }
  };

  validators = {
    notnull: function(val) {
      return val.length > 0;
    },
    notblank: function(val) {
      return _.isString(val) && '' !== val.replace(/^\s+/g, '').replace(/\s+$/g, '');
    },
    required: function(val) {
      var element, _i, _len;
      if (_.isArray(val)) {
        for (_i = 0, _len = val.length; _i < _len; _i++) {
          element = val[_i];
          if (validators.required(val[i])) {
            return true;
          }
        }
        return false;
      }
      return validators.notnull(val) && validators.notblank(val);
    },
    type: function(val, type) {
      var regExp;
      regExp = null;
      switch (type) {
        case 'number':
          regExp = /^-?(?:\d+|\d{1,3}(?:,\d{3})+)?(?:\.\d+)?$/;
          break;
        case 'digits':
          regExp = /^\d+$/;
          break;
        case 'alphanum':
          regExp = /^\w+$/;
          break;
        case 'email':
          regExp = /^((([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+(\.([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+)*)|((\x22)((((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(([\x01-\x08\x0b\x0c\x0e-\x1f\x7f]|\x21|[\x23-\x5b]|[\x5d-\x7e]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(\\([\x01-\x09\x0b\x0c\x0d-\x7f]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]))))*(((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(\x22)))@((([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))$/i;
          break;
        case 'url':
          if (!/(https?|s?ftp|git)/i.test(val)) {
            val = "http://" + val;
          }
          regExp = /^(https?|s?ftp|git):\/\/(((([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:)*@)?(((\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])\.(\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])\.(\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])\.(\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5]))|((([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.?)(:\d*)?)(\/((([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:|@)+(\/(([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:|@)*)*)?)?(\?((([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:|@)|[\uE000-\uF8FF]|\/|\?)*)?(#((([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:|@)|\/|\?)*)?$/i;
          break;
        case 'urlstrict':
          regExp = /^(https?|s?ftp|git):\/\/(((([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:)*@)?(((\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])\.(\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])\.(\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])\.(\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5]))|((([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.?)(:\d*)?)(\/((([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:|@)+(\/(([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:|@)*)*)?)?(\?((([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:|@)|[\uE000-\uF8FF]|\/|\?)*)?(#((([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:|@)|\/|\?)*)?$/i;
          break;
        case 'dateIso':
          regExp = /^(\d{4})\D?(0[1-9]|1[0-2])\D?([12]\d|0[1-9]|3[01])$/;
          break;
        case 'phone':
          regExp = /^((\+\d{1,3}(-| )?\(?\d\)?(-| )?\d{1,5})|(\(?\d{2,6}\)?))(-| )?(\d{3,4})(-| )?(\d{4})(( x| ext)\d{1,5}){0,1}$/;
      }
      if (regExp) {
        return regExp.test(val);
      }
      return false;
    },
    regexp: function(val, regExp, self) {
      return new RegExp(regExp, self.options.regexpFlag || '').test(val);
    },
    minlength: function(val, min) {
      return val.length >= min;
    },
    maxlength: function(val, max) {
      return val.length <= max;
    },
    rangelength: function(val, arrayRange) {
      return val.length >= arrayRange[0] && val.length <= arrayRange[1];
    },
    min: function(val, min) {
      return Number(val) >= min;
    },
    max: function(val, max) {
      return Number(val) <= max;
    },
    range: function(val, arrayRange) {
      return val >= arrayRange[0] && val <= arrayRange[1];
    },
    equalto: function(val, elem, self) {
      self.options.validateIfUnchanged = true;
      return val === $(elem).val();
    },
    mincheck: function(obj, val) {
      return validators.minlength(obj, val);
    },
    maxcheck: function(obj, val) {
      return validators.maxlength(obj, val);
    },
    rangecheck: function(obj, arrayRange) {
      return validators.rangelength(obj, arrayRange);
    }
  };

  messages = {
    defaultMessage: "This value seems to be invalid.",
    type: {
      email: "This value should be a valid email.",
      url: "This value should be a valid url.",
      urlstrict: "This value should be a valid url.",
      number: "This value should be a valid number.",
      digits: "This value should be digits.",
      dateIso: "This value should be a valid date (YYYY-MM-DD).",
      alphanum: "This value should be alphanumeric.",
      phone: "This value should be a valid phone number."
    },
    notnull: "This value should not be null.",
    notblank: "This value should not be blank.",
    required: "This value is required.",
    regexp: "This value seems to be invalid.",
    min: "This value should be greater than or equal to %s.",
    max: "This value should be lower than or equal to %s.",
    range: "This value should be between %s and %s.",
    minlength: "This value is too short. It should have %s characters or more.",
    maxlength: "This value is too long. It should have %s characters or less.",
    rangelength: "This value length is invalid. It should be between %s and %s characters long.",
    mincheck: "You must select at least %s choices.",
    maxcheck: "You must select %s choices or less.",
    rangecheck: "You must select between %s and %s choices.",
    equalto: "This value should be the same."
  };

  formatMesssage = function(message, args) {
    if (!_.isArray(args)) {
      args = [args];
    }
    return message.replace(/%s/g, function(match) {
      return String(args.shift());
    });
  };

  toInt = function(num) {
    return parseInt(num, 10);
  };

  _checksley = function(options) {
    var element, elm, instance, _options;
    elm = this;
    element = $(elm);
    if (!element.is("form, input, select, textarea")) {
      throw "element is not a valid element for checksley";
    }
    instance = element.data("checksley");
    if (instance === void 0 || instance === null) {
      _options = {};
      if (_.isPlainObject(options)) {
        _options = options;
      }
      if (element.is("input[type=radio], input[type=checkbox]")) {
        instance = new checksley.FieldMultiple(element, options);
      } else if (element.is("input, select, textarea")) {
        instance = new checksley.Field(element, options);
      } else {
        instance = new Form(elm, options);
      }
    }
    if (_.isString(options)) {
      switch (options) {
        case "validate":
          return instance.validate();
        case "destroy":
          return instance.destroy();
        case "reset":
          return instance.reset();
      }
    } else {
      return instance;
    }
  };

  Checksley = (function() {
    function Checksley(jq) {
      if (jq === void 0) {
        this.jq = window.jQuery || window.Zepto;
      } else {
        this.jq = jq;
      }
      this.messages = {
        "default": {
          defaultMessage: "Invalid"
        }
      };
      this.lang = this.detectLang();
    }

    Checksley.prototype.updateDefaults = function(options) {
      return _.merge(defaults, options);
    };

    Checksley.prototype.updateValidators = function(options) {
      return _.extend(validators, options);
    };

    Checksley.prototype.updateMessages = function(lang, messages) {
      if (this.messages[lang] === void 0) {
        this.messages[lang] = {};
      }
      return _.merge(this.messages[lang], messages);
    };

    Checksley.prototype.injectPlugin = function() {
      return this.jq.fn.checksley = _checksley;
    };

    Checksley.prototype.setLang = function(lang) {
      return this.lang = lang;
    };

    Checksley.prototype.detectLang = function() {
      return this.jq("html").attr("lang") || "default";
    };

    Checksley.prototype.getMessage = function(key, lang) {
      var message;
      if (lang === void 0) {
        lang = this.lang;
      }
      messages = this.messages[lang];
      if (messages === void 0) {
        messages = {};
      }
      message = messages[key];
      if (message === void 0) {
        if (lang === "default") {
          return this.getMessage("defaultMessage", lang);
        } else {
          return this.getMessage(key, "default");
        }
      }
      return message;
    };

    return Checksley;

  })();

  Field = (function() {
    function Field(elm, options) {
      if (options == null) {
        options = {};
      }
      this.id = _.uniqueId("field-");
      this.element = $(elm);
      this.validatedOnce = false;
      this.options = _.merge({}, defaults, options);
      this.isRadioOrCheckbox = false;
      this.validators = validators;
      this.resetConstraints();
      this.bindEvents();
      this.bindData();
    }

    Field.prototype.bindData = function() {
      return this.element.data("checksley-field", this);
    };

    Field.prototype.unbindData = function() {
      return this.element.data("checksley-field", null);
    };

    Field.prototype.focus = function() {
      return this.element.focus();
    };

    Field.prototype.eventValidate = function(event) {
      var trigger, value;
      trigger = this.element.data("trigger");
      value = this.getValue();
      if (event.type === "keyup" && !/keyup/i.test(trigger) && !this.validatedOnce) {
        return true;
      }
      if (event.type === "change" && !/change/i.test(trigger) && !this.validatedOnce) {
        return true;
      }
      if (value.length < this.options.validationMinlength && !this.validatedOnce) {
        return true;
      }
      return this.validate();
    };

    Field.prototype.unbindEvents = function() {
      return this.element.off("." + this.id);
    };

    Field.prototype.bindEvents = function() {
      var trigger;
      this.unbindEvents();
      trigger = this.element.data("trigger");
      if (_.isString(trigger)) {
        this.element.on("" + trigger + "." + this.id, _.bind(this.eventValidate, this));
      }
      if (this.element.is("select") && trigger !== "change") {
        this.element.on("change." + this.id, _.bind(this.eventValidate, this));
      }
      if (trigger !== "keyup") {
        return this.element.on("keyup." + this.id, _.bind(this.eventValidate, this));
      }
    };

    Field.prototype.errorClassTarget = function() {
      return this.element;
    };

    Field.prototype.resetHtml5Constraints = function() {
      var max, min, type, typeRx;
      if (this.element.prop("required")) {
        this.required = true;
      }
      typeRx = new RegExp(this.element.attr('type'), "i");
      if (typeRx.test("email url number range")) {
        type = this.element.attr('type');
        switch (type) {
          case "range":
            min = this.element.attr('min');
            max = this.element.attr('max');
            if (min && max) {
              return this.constraints[type] = {
                valid: true,
                params: [toInt(min), toInt(max)],
                fn: this.validators[type]
              };
            }
        }
      }
    };

    Field.prototype.resetConstraints = function() {
      var constraint, fn, _ref, _results;
      this.constraints = {};
      this.valid = true;
      this.required = false;
      this.resetHtml5Constraints();
      this.element.addClass('checksley-validated');
      _ref = this.validators;
      _results = [];
      for (constraint in _ref) {
        fn = _ref[constraint];
        if (this.element.data(constraint) === void 0) {
          continue;
        }
        this.constraints[constraint] = {
          valid: true,
          params: this.element.data(constraint),
          fn: fn
        };
        if (constraint === "required") {
          _results.push(this.required = true);
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };

    Field.prototype.hasConstraints = function() {
      return !_.isEmpty(this.constraints);
    };

    Field.prototype.validate = function(showErrors) {
      this.validatedOnce = true;
      if (!this.hasConstraints()) {
        return null;
      }
      if (this.options.listeners.onFieldValidate(this.element, this)) {
        this.reset();
        return null;
      }
      if (!this.required && this.getValue() === "") {
        this.reset();
        return null;
      }
      return this.applyValidators(showErrors);
    };

    Field.prototype.applyValidators = function(showErrors) {
      var data, listeners, name, val, valid, _ref;
      if (showErrors === void 0) {
        showErrors = this.options.showErrors;
      }
      val = this.getValue();
      valid = true;
      listeners = this.options.listeners;
      if (showErrors) {
        this.removeErrors();
      }
      _ref = this.constraints;
      for (name in _ref) {
        data = _ref[name];
        data.valid = data.fn(this.getValue(), data.params, this);
        if (data.valid === false) {
          valid = false;
          if (showErrors) {
            this.manageError(name, data);
          }
          listeners.onFieldError(this.element, data, this);
        } else {
          listeners.onFieldSuccess(this.element, data, this);
        }
      }
      this.handleClasses(valid);
      return valid;
    };

    Field.prototype.handleClasses = function(valid) {
      var classHandlerElement, errorClass, successClass;
      classHandlerElement = this.options.errors.classHandler(this.element, false);
      errorClass = this.options.errorClass;
      successClass = this.options.successClass;
      switch (valid) {
        case null:
          classHandlerElement.removeClass(errorClass);
          return classHandlerElement.removeClass(successClass);
        case false:
          classHandlerElement.removeClass(successClass);
          return classHandlerElement.addClass(errorClass);
        case true:
          classHandlerElement.removeClass(errorClass);
          return classHandlerElement.addClass(successClass);
      }
    };

    Field.prototype.manageError = function(name, constraint) {
      var message;
      if (name === "type") {
        message = checksley.getMessage("type")[constraint.params];
      } else {
        message = checksley.getMessage(name);
      }
      if (message === void 0) {
        message = checksley.getMessage("default");
      }
      if (constraint.params) {
        message = formatMesssage(message, _.clone(constraint.params, true));
      }
      return this.addError(this.makeErrorElement(name, message));
    };

    Field.prototype.makeErrorElement = function(constraintName, message) {
      var element;
      element = $("<li />", {
        "class": "checksley-" + constraintName
      });
      element.html(message);
      element.addClass(constraintName);
      return element;
    };

    Field.prototype.addError = function(errorElement) {
      var container;
      container = this.getErrorContainer();
      if (this.options.errors.onlyOneErrorElement) {
        container.empty();
      }
      return container.append(errorElement);
    };

    Field.prototype.reset = function() {
      this.handleClasses(null);
      this.resetConstraints();
      return this.removeErrors();
    };

    Field.prototype.removeErrors = function() {
      return $("#" + (this.errorContainerId())).remove();
    };

    Field.prototype.getValue = function() {
      return this.element.val();
    };

    Field.prototype.errorContainerId = function() {
      return "checksley-error-" + this.id;
    };

    Field.prototype.errorContainerClass = function() {
      return "checksley-error-list";
    };

    Field.prototype.getErrorContainer = function() {
      var container, definedContainer, errorContainerEl, params, preferenceSelector;
      errorContainerEl = $("#" + (this.errorContainerId()));
      if (errorContainerEl.length === 1) {
        return errorContainerEl;
      }
      params = {
        "class": this.errorContainerClass(),
        "id": this.errorContainerId()
      };
      errorContainerEl = $("<ul />", params);
      definedContainer = this.element.data('error-container');
      if (definedContainer === void 0) {
        if (this.isRadioOrCheckbox) {
          errorContainerEl.insertAfter(this.element.parent());
        } else {
          errorContainerEl.insertAfter(this.element);
        }
        return errorContainerEl;
      }
      if (this.options.errors.containerGlobalSearch) {
        container = $(definedContainer);
      } else {
        container = this.element.closest(definedContainer);
      }
      preferenceSelector = this.options.errors.containerPreferenceSelector;
      if (container.find(preferenceSelector).length === 1) {
        container = container.find(preferenceSelector);
      }
      container.append(errorContainerEl);
      return errorContainerEl;
    };

    Field.prototype.destroy = function() {
      this.unbindEvents();
      this.removeErrors();
      return this.unbindData();
    };

    Field.prototype.setForm = function(form) {
      return this.form = form;
    };

    return Field;

  })();

  FieldMultiple = (function(_super) {
    __extends(FieldMultiple, _super);

    function FieldMultiple(elm, options) {
      FieldMultiple.__super__.constructor.call(this, elm, options);
      this.isRadioOrCheckbox = true;
      this.isRadio = this.element.is("input[type=radio]");
      this.isCheckbox = this.element.is("input[type=checkbox]");
    }

    FieldMultiple.prototype.getSibligns = function() {
      var group;
      group = this.element.data("group");
      if (group === void 0) {
        return "input[name=" + (this.element.attr('name')) + "]";
      } else {
        return "[data-group=\"" + group + "\"]";
      }
    };

    FieldMultiple.prototype.getValue = function() {
      var element, values, _i, _len, _ref;
      if (this.isRadio) {
        return $("" + (this.getSibligns()) + ":checked").val() || '';
      }
      if (this.isCheckbox) {
        values = [];
        _ref = $("" + (this.getSibligns()) + ":checked");
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          element = _ref[_i];
          values.push($(element).val());
        }
        return values;
      }
    };

    FieldMultiple.prototype.unbindEvents = function() {
      var element, _i, _len, _ref, _results;
      _ref = $(this.getSibligns());
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        element = _ref[_i];
        _results.push($(element).off("." + this.id));
      }
      return _results;
    };

    FieldMultiple.prototype.bindEvents = function() {
      var element, trigger, _i, _len, _ref, _results;
      this.unbindEvents();
      trigger = this.element.data("trigger");
      _ref = $(this.getSibligns());
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        element = _ref[_i];
        element = $(element);
        if (_.isString(trigger)) {
          element.on("" + trigger + "." + this.id, _.bind(this.eventValidate, this));
        }
        if (trigger !== "change") {
          _results.push(element.on("change." + this.id, _.bind(this.eventValidate, this)));
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };

    return FieldMultiple;

  })(Field);

  Form = (function() {
    function Form(elm, options) {
      if (options == null) {
        options = {};
      }
      this.id = _.uniqueId("checksleyform-");
      this.element = $(elm);
      this.options = _.extend({}, defaults, options);
      this.initializeFields();
      this.bindEvents();
      this.bindData();
    }

    Form.prototype.bindData = function() {
      return this.element.data("checksley", this);
    };

    Form.prototype.unbindData = function() {
      return this.element.data("checksley", null);
    };

    Form.prototype.initializeFields = function() {
      var element, field, fieldElm, _i, _len, _ref, _results;
      this.fields = [];
      _ref = this.element.find(this.options.inputs);
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        fieldElm = _ref[_i];
        element = $(fieldElm);
        if (element.is(this.options.excluded)) {
          continue;
        }
        if (element.is("input[type=radio], input[type=checkbox]")) {
          field = new checksley.FieldMultiple(fieldElm, this.options);
        } else {
          field = new checksley.Field(fieldElm, this.options);
        }
        field.setForm(this);
        _results.push(this.fields.push(field));
      }
      return _results;
    };

    Form.prototype.validate = function() {
      var field, invalidFields, valid, _i, _len, _ref;
      valid = true;
      invalidFields = [];
      _ref = this.fields;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        field = _ref[_i];
        if (field.validate() === false) {
          valid = false;
          invalidFields.push(field);
        }
      }
      if (!valid) {
        switch (this.options.focus) {
          case "first":
            invalidFields[0].focus();
            break;
          case "last":
            invalidFields[invalidFields.length].focus();
        }
      }
      return valid;
    };

    Form.prototype.bindEvents = function() {
      var self;
      self = this;
      this.unbindEvents();
      return this.element.on("submit." + this.id, function(event) {
        var ok;
        ok = self.validate();
        self.options.listeners.onFormSubmit(ok, event, self);
        if (self.options.interceptSubmit && !ok) {
          return event.preventDefault();
        }
      });
    };

    Form.prototype.unbindEvents = function() {
      return this.element.off("." + this.id);
    };

    Form.prototype.removeErrors = function() {
      var field, _i, _len, _ref, _results;
      _ref = this.fields;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        field = _ref[_i];
        _results.push(field.reset());
      }
      return _results;
    };

    Form.prototype.destroy = function() {
      var field, _i, _len, _ref;
      this.unbindEvents();
      this.unbindData();
      _ref = this.fields;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        field = _ref[_i];
        field.destroy();
      }
      return this.field = [];
    };

    Form.prototype.reset = function() {
      var field, _i, _len, _ref, _results;
      _ref = this.fields;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        field = _ref[_i];
        _results.push(field.reset());
      }
      return _results;
    };

    return Form;

  })();

  checksley = new Checksley();

  checksley.updateMessages("default", messages);

  checksley.injectPlugin();

  checksley.Checksley = Checksley;

  checksley.Form = Form;

  checksley.Field = Field;

  checksley.FieldMultiple = FieldMultiple;

  this.checksley = checksley;

}).call(this);
