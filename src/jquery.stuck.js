(function() {
  (function($) {
    return $.fn.stuck = function(opts) {
      var Stuck;
      Stuck = (function() {
        Stuck.prototype.elements = [];

        Stuck.prototype.resizing = false;

        function Stuck(w, opts) {
          this.window = w;
          this.body = $("body");
          this.loadElements();
          this.calculateTopOffset();
          if (this.isIOS()) {
            this.body.on({
              touchmove: (function(_this) {
                return function() {
                  return _this.update();
                };
              })(this)
            });
          }
          this.window.scroll(((function(_this) {
            return function() {
              return _this.update();
            };
          })(this)));
          this.window.resize(((function(_this) {
            return function() {
              return _this.resize();
            };
          })(this)));
          this.update();
          this;
        }

        Stuck.prototype.isIOS = function() {
          return this._isIOS || (this._isIOS = /(iPad|iPhone|iPod)/g.test(navigator.userAgent));
        };

        Stuck.prototype.resize = function() {
          this.resizing = true;
          this.calculateTopOffset();
          this.update();
        };

        Stuck.prototype.loadElements = function() {
          var classes, container, divs, i, name, node, release, spacer, top, x, y;
          divs = $(".stuck");
          i = divs.length;
          y = 0;
          while (i--) {
            node = divs.eq(y);
            y++;
            release = false;
            container = '';
            classes = node.attr("class").split(/\s+/);
            spacer = $("<div/>");
            x = classes.length;
            while (x--) {
              name = classes[x];
              if (name === "release") {
                release = true;
                container = node.closest(".release-container");
              }
              if (!(name === "stuck" || name === "release")) {
                spacer.addClass(name);
              }
            }
            spacer.height(node.outerHeight()).hide().css("background-color", "transparent").insertBefore(node);
            top = node.offset().top - parseInt(node.css('margin-top'));
            this.elements.push({
              node: node,
              spacer: spacer,
              top: top,
              top_offset: 0,
              fixed: false,
              release: release,
              container: container,
              contained: false
            });
          }
        };

        Stuck.prototype.calculateTopOffset = function() {
          var collide_flag, collide_y, collision, el, elements, i, matrix, max_height, row_element, value, x, y, z;
          matrix = [];
          i = this.elements.length;
          x = 0;
          while (i--) {
            el = this.elements[x];
            x++;
            y = matrix.length;
            if (y === 0) {
              if (!el.release) {
                matrix.push([el]);
              }
            } else {
              collide_flag = false;
              while (y-- && !collide_flag) {
                max_height = 0;
                elements = matrix[y];
                z = elements.length;
                while (z--) {
                  row_element = elements[z];
                  collision = this.collide(row_element.node, el.node);
                  if (collision) {
                    value = row_element.top_offset + row_element.node.outerHeight(true);
                    if (value > max_height) {
                      max_height = value;
                    }
                    collide_flag = true;
                    if (matrix[y + 1] != null) {
                      collide_y = y + 1;
                    } else {
                      collide_y = -1;
                    }
                  } else {
                    if (y === 0) {
                      collide_y = 0;
                    }
                  }
                }
              }
              if (collide_flag) {
                el.top_offset = max_height;
                if (!el.release) {
                  if (collide_y >= 0) {
                    matrix[collide_y].push(el);
                  } else {
                    matrix.push([el]);
                  }
                }
              } else {
                el.top_offset = 0;
                if (!el.release) {
                  matrix[0].push(el);
                }
              }
            }
          }
        };

        Stuck.prototype.collide = function(node1, node2) {
          var n1l, n2l;
          n1l = node1.offset().left;
          n2l = node2.offset().left;
          if (n1l === n2l) {
            return true;
          } else if (n1l < n2l) {
            if (Math.floor(n1l) + node1.width() > Math.ceil(n2l)) {
              return true;
            } else {
              return false;
            }
          } else {
            if (Math.floor(n2l) + node2.width() > Math.ceil(n1l)) {
              return true;
            } else {
              return false;
            }
          }
        };

        Stuck.prototype.update = function() {
          var el, i, window_top;
          window_top = this.window.scrollTop();
          i = this.elements.length;
          while (i--) {
            el = this.elements[i];
            if (this.resizing) {
              if (el.fixed) {
                el.top = el.spacer.offset().top - parseInt(el.spacer.css('margin-top'));
              } else {
                el.top = el.node.offset().top - parseInt(el.node.css('margin-top'));
              }
              if (el.fixed) {
                el.node.css({
                  top: el.top_offset,
                  left: el.spacer.offset().left,
                  width: el.spacer.outerWidth()
                });
              }
              if (el.contained && window_top > (el.container.offset().top + el.container.height() - el.node.height() - el.top_offset)) {
                el.node.css({
                  position: "absolute",
                  top: el.container.height() - el.node.height(),
                  left: '',
                  width: '',
                  "z-index": ''
                });
              }
            }
            if (el.fixed && el.release && !el.contained && window_top > (el.container.offset().top + el.container.height() - el.node.height() - el.top_offset)) {
              el.contained = true;
              el.container.css("position", "relative");
              el.node.css({
                position: "absolute",
                top: el.container.height() - el.node.height(),
                left: '',
                width: '',
                "z-index": ''
              });
            }
            if (el.contained && window_top < (el.container.offset().top + el.container.height() - el.node.height() - el.top_offset)) {
              el.contained = false;
              el.container.css("position", '');
              el.node.css({
                position: "fixed",
                top: el.top_offset,
                left: el.spacer.offset().left,
                width: el.spacer.outerWidth(),
                "z-index": 99
              });
            }
            if (!el.fixed && window_top >= el.top - el.top_offset) {
              el.fixed = true;
              el.spacer.show();
              el.node.css({
                position: "fixed",
                top: el.top_offset,
                left: el.spacer.offset().left,
                width: el.spacer.outerWidth(),
                "z-index": 99
              });
            }
            if (el.fixed && window_top < el.top - el.top_offset) {
              el.fixed = false;
              el.spacer.hide();
              el.node.css({
                position: "relative",
                top: '',
                left: '',
                width: '',
                "z-index": ''
              });
            }
          }
          this.resizing = false;
        };

        Stuck.prototype.destroy = function() {
          var i;
          i = this.elements.length;
          while (i--) {
            this.elements[i].spacer.remove();
          }
          this.window.unbind('scroll');
          this.window.unbind('resize');
          this.window = this.elements = null;
        };

        return Stuck;

      })();
      return new Stuck(this, opts);
    };
  })(jQuery);

}).call(this);
