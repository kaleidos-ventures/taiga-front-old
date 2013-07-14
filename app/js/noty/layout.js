;(function($) {

    $.noty.layouts.top = {
        name: 'top',
        options: {},
        container: {
            object: '<ul id="noty_top_layout_container" />',
            selector: 'ul#noty_top_layout_container',
            style: function() {
                $(this).css({
                    top: 0,
                    left: '5%',
                    position: 'fixed',
                    width: '90%',
                    height: 'auto',
                    margin: 0,
                    padding: 0,
                    listStyleType: 'none',
                    zIndex: 9999999
                });
            }
        },
        parent: {
            object: '<li />',
            selector: 'li',
            css: {}
        },
        css: {
            display: 'none'
        },
        addClass: ''
    };

})(jQuery);
;(function($) {

    $.noty.layouts.topCenter = {
        name: 'topCenter',
        options: { // overrides options

        },
        container: {
            object: '<ul id="noty_topCenter_layout_container" />',
            selector: 'ul#noty_topCenter_layout_container',
            style: function() {
                $(this).css({
                    top: 20,
                    left: 0,
                    position: 'fixed',
                    width: '310px',
                    height: 'auto',
                    margin: 0,
                    padding: 0,
                    listStyleType: 'none',
                    zIndex: 10000000
                });

                $(this).css({
                    left: ($(window).width() - $(this).outerWidth(false)) / 2 + 'px'
                });
            }
        },
        parent: {
            object: '<li />',
            selector: 'li',
            css: {}
        },
        css: {
            display: 'none',
            width: '310px'
        },
        addClass: ''
    };

})(jQuery);
