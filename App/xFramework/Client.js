getUrl = function(uri)
{
    return window.location.protocol + "//" + window.location.hostname + "/" + uri;
}

class Model
{
    constructor(name, id)
    {
        this.name = name;
        this.id = id || -1;
    }

    delete(callback)
    {
        $.post(getUrl('App/Framework/ModelBinding.cfm'), {
            'mb_method': 'delete',
            'mb_name': this.name,
            'mb_id': this.id
        }, callback);
    }

    bindDelete(element, event, callback)
    {
        var _this = this;
        $(document).on(event, element, function(e) {
            var el = $(this);
            _this.id = el.data('id');
            _this.delete(function() { callback(el); });
            e.preventDefault();
        });
    }

    save(data, callback)
    {
        var d = new FormData();
        d.append('mb_method', 'save');
        d.append('mb_name', this.name);
        d.append('mb_id', this.id);

        $.each(data, function(key, input) {
            d.append(input.name, input.value);
        });

        $.ajax({
            type: 'POST',
            url: getUrl('App/Framework/ModelBinding.cfm'),
            data: d,
            contentType: false,
            processData: false,
            success: function(data) {
                callback(data);
            }
        });
    }

    create(data, callback)
    {
        var d = new FormData();
        d.append('mb_method', 'create');
        d.append('mb_name', this.name);
        d.append('mb_id', this.id);

        $.each(data, function(key, input) {
            d.append(input.name, input.value);
        });

        $.ajax({
            type: 'POST',
            url: getUrl('App/Framework/ModelBinding.cfm'),
            data: d,
            contentType: false,
            processData: false,
            success: function(data) {
                var obj = JSON.parse(data);
                callback(obj);
            }
        });
    }

    bindSave(element, event, callback)
    {
        var _this = this;
        $(document).on(event, element, function(e) {
            _this.id = $(this).data('id');
            _this.save($(this).serializeArray(), callback);
            e.preventDefault();
        });
    }

    bindCreate(element, event, callback)
    {
        var _this = this;
        $(document).on(event, element, function(e) {
            _this.id = -1;
            _this.create($(this).serializeArray(), callback);
            e.preventDefault();
        });
    }
}

;(function($) {
    $.fn.routeContent = function(controller, method, args)
    {
        var el = $(this);

        $.ajax({
            type: 'POST',
            url: getUrl('App/Framework/Request.cfm?controller=' + controller + '&method=' + method),
            data: args,
            success: function(data) {
                el.html(data);
            }
        });
    }
})(jQuery);
