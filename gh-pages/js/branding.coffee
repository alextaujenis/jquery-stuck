class App.Branding

  constructor: (el)->
    # Memoize for performance
    @el = $(el)
    @window = $(window)
    @offset = @el.height() + @el.offset().top

    # Resize on page load
    @resize()

    # Resize on window resize
    @window.resize => @resize()
    return

  resize: ->
    # Sneek peek the top 25% of content below the branding window
    value = ((@window.height() * 0.80) - @offset) / 2
    value = 0 if value < 0

    @el.css
      "padding-top":    value
      "padding-bottom": value

    return