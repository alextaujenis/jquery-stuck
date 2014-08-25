popup = document.URL.split("?")[1]
window.open("#{document.URL}?popup=true","popupWindow","width=#{$(window).width()},height=#{$(window).height()},scrollbars=yes") if !popup?

describe "jQuery.Autohide", ->
  beforeEach ->
    # Extend the page
    @body = $("body")
    @body.height(5000)

    # Put a container at the top of the page
    @container_div = $("<div/>")
    @body.prepend(@container_div)

    # Push the divs down the page
    @spacer_div = $("<div/>")
    @spacer_div.width("100%").height(100)
    @container_div.append(@spacer_div)

    # Add the stuck div
    @stuck_div = $('<div class="row stuck"></div>')
    @stuck_div.height(100)
    @container_div.append(@stuck_div)

    # Add the second stuck div
    @second_stuck_div = $('<div class="row stuck"></div>')
    @second_stuck_div.height(100)
    @container_div.append(@second_stuck_div)

    # Add the release container
    @release_container_div = $('<div class="row release-container"></div>')
    @release_container_div.height(2000)
    @container_div.append(@release_container_div)

    # Add the stuck / release div
    @release_div = $('<div class="columns stuck release"</div>')
    @release_div.height(100)
    @release_container_div.append(@release_div)

    # Create a row for the resize divs
    @row = $('<div class="row"></div>')

    # Add a tall div that is half the width
    @column1 = $('<div class="columns medium-6"></div>')
    @column1.height(1000)
    @row.append(@column1)

    # Add another half width div that will pop underneath the above div on resize
    @column2 = $('<div class="columns medium-6 stuck"></div>')
    @column2.height(100)
    @row.append(@column2)

    # Add the row to the container
    @container_div.append(@row)

    # Memoize for scrolling
    @html_body = $("html, body")

    # Initialize the plugin
    @stuck_plugin = $(window).stuck()
    return

  afterEach ->
    # Fix the window size
    window.resizeTo(1600,900) if popup?

    # Go to the top of the page
    @html_body.animate({scrollTop: 0}, 0)

    # Plugin cleanup
    @stuck_plugin.remove()

    # Test cleanup
    @spacer_div.remove()
    @stuck_div.remove()
    @second_stuck_div.remove()
    @release_div.remove()
    @release_container_div.remove()
    @column1.remove()
    @column2.remove()
    @row.remove()
    @container_div.remove()

    # Fix the page height
    @body.height("auto")
    return

  # Have control of the popup: resize tests
  if popup?
    describe "Resize", ->
      it "releases the element if it jumps down the page on resize", (done)->
        # Compute the stacked height for the column
        stacked_height = @stuck_div.height() + @second_stuck_div.height()

        # The column should not be stuck to the page
        expect(@column2.position().top).not.toEqual(stacked_height)

        # Scroll a little bit past the column
        @html_body
          .animate({scrollTop: @column2.offset().top + 100}, 250)
          .promise().done =>
            # The column should be stacked
            expect(@column2.position().top).toEqual(stacked_height)

            # Make the window small
            window.resizeTo(300,900)

            # Wait for the window resize
            setTimeout =>
              # The column should have jumped down the page and should not be stacked
              expect(@column2.position().top).not.toEqual(stacked_height)
              done()
              return
            , 250
        return

      it "stacks the element if it jumps up the page on resize", (done)->
        # Compute the stacked height for the column
        stacked_height = @stuck_div.height() + @second_stuck_div.height()

        # Resize the page to make it skinny
        window.resizeTo(300, 900)

        # Wait for the resize
        setTimeout =>
          # Scroll half way down the first column's height
          @html_body
            .animate({scrollTop: @column1.offset().top + (@column1.height() / 2)}, 250)
            .promise().done =>
              # The second column should not be stacked
              expect(@column2.position().top).not.toEqual(stacked_height)

              # Make the window big
              window.resizeTo(1600,900)

              # Wait for the window resize
              setTimeout =>
                # The column should have jumped up the page and be stacked
                expect(@column2.position().top).toEqual(stacked_height)
                done()
                return
              , 250
          return
        , 250
        return

      it "adjusts the element left position and width on window resize after scrolling past it", (done)->
        # Make the window small
        window.resizeTo(300,900)

        # Wait for the window resize
        setTimeout =>

          # Scroll down
          @html_body
            .animate({scrollTop: @stuck_div.offset().top + 100}, 250)
            .promise().done =>
              # The element should be stuck to the top and left
              expect(@stuck_div.position().top).toEqual(0)
              expect(@stuck_div.position().left).toEqual(0)

              # Make the window big
              window.resizeTo(1600,900)

              # Wait for the window resize
              setTimeout =>
                # The element should be stuck to the top repositioned left
                expect(@stuck_div.position().top).toEqual(0)
                expect(@stuck_div.position().left).not.toEqual(0)
                done()
                return
              , 250

          return
        , 250
        return

  # Scroll tests
  else
    describe "Scroll", ->
      it "sticks an element to the top of the page after scrolling past it", (done)->
        # Make sure the element isn't already stuck to the top
        expect(@stuck_div.position().top).not.toEqual(0)

        # Scroll down
        @html_body
          .animate({scrollTop: 2000}, 250)
          .promise().done =>

            # The element should be stuck to the top
            expect(@stuck_div.position().top).toEqual(0)
            done()
            return
        return

      it "returns the element to the start position after scrolling past it then back up", (done)->
        # Save the start position
        stuck_top = @stuck_div.position().top

        # Make sure the element isn't already stuck to the top
        expect(stuck_top).not.toEqual(0)

        # Scroll down
        @html_body
          .animate({scrollTop: 2000}, 250)
          .promise().done =>

            # Scroll back up
            @html_body
              .animate({scrollTop: 0}, 500)
              .promise().done =>

                # Compare existing position to the start position after scrolling
                expect(@stuck_div.position().top).toEqual(stuck_top)
                done()
                return
        return

    describe "Stack", ->
      it "stacks the second div underneath the first div", (done)->
        # Scroll down
        @html_body
          .animate({scrollTop: 2000}, 250)
          .promise().done =>

            # The first div should be stuck to the top
            expect(@stuck_div.position().top).toEqual(0)

            # The second div should be stuck to the bottom of the first div
            expect(@second_stuck_div.position().top).toEqual(@stuck_div.height())
            done()
            return
        return

      it "returns the second div to the start position after scrolling past it then back up", (done)->
        # Save the start position
        stuck_top = @second_stuck_div.position().top

        # Make sure the element isn't already stuck to the top
        expect(stuck_top).not.toEqual(0)

        # Scroll down
        @html_body
          .animate({scrollTop: 2000}, 250)
          .promise().done =>

            # Scroll back up
            @html_body
              .animate({scrollTop: 0}, 500)
              .promise().done =>

                # Compare existing position to the start position after scrolling
                expect(@second_stuck_div.position().top).toEqual(stuck_top)
                done()
                return
        return

    describe "Release", ->
      it "stacks the stuck div underneath the second div after scrolling past it", (done)->
        # Scroll past the top of the stuck container, but not past the bottom
        @html_body
          .animate({scrollTop: 1000}, 250)
          .promise().done =>

            # The third div should be stuck to the bottom of the second div
            top_offset = @stuck_div.height() + @second_stuck_div.height()
            expect(@release_div.position().top).toEqual(top_offset)
            done()
            return
        return

      it "sticks the stuck div to the bottom of the release container after scrolling past the bottom of the container", (done)->
        # Scroll past the bottom of the stuck container
        @html_body
          .animate({scrollTop: 3000}, 250)
          .promise().done =>

            # The third div should be stuck at the bottom of the container div
            expected_offset = @release_container_div.offset().top + @release_container_div.height() - @release_div.height()
            expect(@release_div.offset().top).toEqual(expected_offset)
            done()
            return
        return

      it "stacks the stuck div underneath the second div after scrolling past the bottom of the release container then back up", (done)->
        # Save the start position
        stuck_top = @second_stuck_div.position().top

        # Make sure the element isn't already stuck to the top
        expect(stuck_top).not.toEqual(0)

        # Scroll down
        @html_body
          .animate({scrollTop: 3000}, 250)
          .promise().done =>

            # Scroll back up
            @html_body
              .animate({scrollTop: 1000}, 500)
              .promise().done =>

                # The release div should be stuck to the bottom of the second div
                top_offset = @stuck_div.height() + @second_stuck_div.height()
                expect(@release_div.position().top).toEqual(top_offset)
                done()
                return
        return

      it "returns the stuck div to the start position after scrolling past it then back up", (done)->
        # Save the start position
        start_top = @release_div.position().top

        # Make sure the element isn't already stuck to the top
        expect(start_top).not.toEqual(0)

        # Scroll down
        @html_body
          .animate({scrollTop: 3000}, 250)
          .promise().done =>

            # Scroll back up
            @html_body
              .animate({scrollTop: 0}, 500)
              .promise().done =>

                # Compare existing position to the start position after scrolling
                expect(@release_div.position().top).toEqual(start_top)
                done()
                return
        return