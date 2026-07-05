/**
    * selectImages
    * menuleft
    * tabs
    * progresslevel
    * collapse_menu
    * fullcheckbox
    * showpass
    * gallery
    * coppy
    * select_colors_theme
    * icon_function
    * box_search
    * preloader
*/

; (function ($) {

  "use strict";

  var selectImages = function () {
    if ($(".image-select").length > 0) {
      const selectIMG = $(".image-select");
      selectIMG.find("option").each((idx, elem) => {
        const selectOption = $(elem);
        const imgURL = selectOption.attr("data-thumbnail");
        if (imgURL) {
          selectOption.attr(
            "data-content",
            "<img src='%i'/> %s"
              .replace(/%i/, imgURL)
              .replace(/%s/, selectOption.text())
          );
        }
      });
      selectIMG.selectpicker();
    }
  };

  var menuleft = function () {
    if ($('div').hasClass('section-menu-left')) {
      var bt =$(".section-menu-left").find(".has-children");
      bt.on("click", function () {
        var args = { duration: 200 };
        if ($(this).hasClass("active")) {
          $(this).children(".sub-menu").slideUp(args);
          $(this).removeClass("active");
        } else {
          $(".sub-menu").slideUp(args);
          $(this).children(".sub-menu").slideDown(args);
          $(".menu-item.has-children").removeClass("active");
          $(this).addClass("active");
        }
      });
      $('.sub-menu-item').on('click', function(event){
        event.stopPropagation();
      });
    }
  };

  var tabs = function(){
    $('.widget-tabs').each(function(){
        $(this).find('.widget-content-tab').children().hide();
        $(this).find('.widget-content-tab').children(".active").show();
        $(this).find('.widget-menu-tab').find('li').on('click',function(){
            var liActive = $(this).index();
            var contentActive=$(this).siblings().removeClass('active').parents('.widget-tabs').find('.widget-content-tab').children().eq(liActive);
            contentActive.addClass('active').fadeIn("slow");
            contentActive.siblings().removeClass('active');
            $(this).addClass('active').parents('.widget-tabs').find('.widget-content-tab').children().eq(liActive).siblings().hide();
        });
    });
  };

  $('ul.dropdown-menu.has-content').on('click', function(event){
    event.stopPropagation();
  });
  $('.button-close-dropdown').on('click', function(){
    $(this).closest('.dropdown').find('.dropdown-toggle').removeClass('show');
    $(this).closest('.dropdown').find('.dropdown-menu').removeClass('show');
  });

  var progresslevel = function () {
    if ($('div').hasClass('progress-level-bar')) {
    var bars = document.querySelectorAll('.progress-level-bar > span');
    setInterval(function(){
    bars.forEach(function(bar){
      var t1 = parseFloat(bar.dataset.progress);
      var t2 = parseFloat(bar.dataset.max);
      var getWidth = ( t1 / t2) * 100;
      bar.style.width = getWidth + '%';
    });
    }, 500);
  }}

  var collapse_menu = function () {
    $(".button-show-hide").on("click", function () {
      $('.layout-wrap').toggleClass('full-width');
    })
  }

  var fullcheckbox = function () {
    $('.total-checkbox').on('click', function () {
      if ( $(this).is(':checked') ) {
        $(this).closest('.wrap-checkbox').find('.checkbox-item').prop('checked', true);
      } else {
        $(this).closest('.wrap-checkbox').find('.checkbox-item').prop('checked', false);
      }
    });
  };

  var showpass = function() {
    $(".show-pass").on("click", function () {
      $(this).toggleClass("active");
      var input = $(this).parents(".password").find(".password-input");

      if (input.attr("type") === "password") {
        input.attr("type", "text");
      } else if (input.attr("type") === "text") {
        input.attr("type", "password");
      }
    });
  }

  var gallery = function() {
    $(".button-list-style").on("click", function () {
      $(".wrap-gallery-item").addClass("list");
    });
    $(".button-grid-style").on("click", function () {
      $(".wrap-gallery-item").removeClass("list");
    });
  }

  var coppy = function() {
    $(".button-coppy").on("click", function () {
      myFunction()
    });
    function myFunction() {
      var copyText = document.getElementsByClassName("coppy-content");
      navigator.clipboard.writeText(copyText.text);
    }
  }

  var select_colors_theme = function () {
    if ($('div').hasClass("select-colors-theme")) {
      $(".select-colors-theme .item").on("click", function (e) {
        $(this).parents(".select-colors-theme").find(".active").removeClass("active");
        $(this).toggleClass("active");
      })
    }
  }

  var icon_function = function () {
    if ($('div').hasClass("list-icon-function")) {
      $(".list-icon-function .trash").on("click", function (e) {
        $(this).parents(".product-item").remove();
        $(this).parents(".attribute-item").remove();
        $(this).parents(".countries-item").remove();
        $(this).parents(".user-item").remove();
        $(this).parents(".roles-item").remove();
      })
    }
  }

  var box_search=function(){
        
    $(document).on('click',function(e){
      var clickID=e.target.id;if((clickID!=='s')){
          $('.box-content-search').removeClass('active');
      }});
    $(document).on('click',function(e){
        var clickID=e.target.class;if((clickID!=='a111')){
            $('.show-search').removeClass('active');
    }});
        
    $('.show-search').on('click',function(event){
      event.stopPropagation();}
    );
    $('.search-form').on('click',function(event){
      event.stopPropagation();}
    );
    var input =  $('.header-dashboard').find('.form-search').find('input');
    input.on('input', function() {
      if ($(this).val().trim() !== '') {
        $('.box-content-search').addClass('active');
      } else {
        $('.box-content-search').removeClass('active');
      }
    });
   
  }

  var retinaLogos = function() {
    var retina = window.devicePixelRatio > 1 ? true : false;
      if(retina) {
        if ($(".dark-theme").length > 0) {
          $('#logo_header').attr({src:'images/logo/logo.png',width:'154px',height:'52px'});
        } else {
          $('#logo_header').attr({src:'images/logo/logo.png',width:'154px',height:'52px'});
        }
      }
  };  

  var popupImageOptimizer = function () {
    var input = document.querySelector('[data-popup-image-input]');
    if (!input) return;

    var button = document.querySelector('[data-popup-submit]');
    var note = document.querySelector('[data-popup-note]');

    function setFile(file) {
      var dt = new DataTransfer();
      dt.items.add(file);
      input.files = dt.files;
    }

    function loadImage(file) {
      return new Promise(function(resolve, reject) {
        var reader = new FileReader();
        reader.onload = function(event) {
          var img = new Image();
          img.onload = function() { resolve(img); };
          img.onerror = reject;
          img.src = event.target.result;
        };
        reader.onerror = reject;
        reader.readAsDataURL(file);
      });
    }

    function toBlob(canvas, quality) {
      return new Promise(function(resolve) {
        canvas.toBlob(resolve, 'image/webp', quality);
      });
    }

    async function makeSmall(file) {
      if (!file || !file.type || !file.type.startsWith('image/')) return file;
      if (file.size <= 1700 * 1024) return file;

      var img = await loadImage(file);
      var limit = 1100;
      var scale = Math.min(1, limit / Math.max(img.width, img.height));
      var width = Math.max(1, Math.round(img.width * scale));
      var height = Math.max(1, Math.round(img.height * scale));

      var canvas = document.createElement('canvas');
      canvas.width = width;
      canvas.height = height;
      var ctx = canvas.getContext('2d');
      ctx.clearRect(0, 0, width, height);
      ctx.drawImage(img, 0, 0, width, height);

      var quality = 0.9;
      var blob = await toBlob(canvas, quality);
      while (blob && blob.size > 1700 * 1024 && quality > 0.55) {
        quality -= 0.08;
        blob = await toBlob(canvas, quality);
      }

      if (!blob || blob.size >= file.size) return file;
      return new File([blob], 'popup-' + Date.now() + '.webp', { type: 'image/webp' });
    }

    input.addEventListener('change', async function () {
      var file = input.files && input.files[0] ? input.files[0] : null;
      if (!file) return;

      var oldSize = file.size;
      if (note) note.textContent = 'Menyiapkan gambar...';
      input.disabled = true;
      if (button) button.disabled = true;

      try {
        var prepared = await makeSmall(file);
        setFile(prepared);
        var beforeKb = Math.round(oldSize / 1024);
        var afterKb = Math.round(prepared.size / 1024);
        if (note) {
          note.textContent = prepared.size < oldSize
            ? 'Gambar otomatis diperkecil: ' + beforeKb + ' KB menjadi ' + afterKb + ' KB.'
            : 'Gambar siap diupload: ' + afterKb + ' KB.';
        }
      } catch (e) {
        if (note) note.textContent = 'Gambar siap diupload.';
      } finally {
        input.disabled = false;
        if (button) button.disabled = false;
      }
    });
  };

  var preloader = function () {
    setTimeout(function () {
    $("#preload").fadeOut("slow", function () {
        $(this).remove();
    });
    }, 1000);
  };


  // Dom Ready
  $(function () {
    selectImages();
    menuleft();
    tabs();
    progresslevel();
    collapse_menu();
    fullcheckbox();
    showpass();
    gallery();
    coppy();
    select_colors_theme();
    icon_function();
    box_search();
    retinaLogos();
    popupImageOptimizer();
    preloader();
    
  });

})(jQuery);
