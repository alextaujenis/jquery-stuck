# jQuery Stuck v1.0.2
# (c) 2014 Alex Taujenis
# Distributed under the MIT license

(($) ->
  $.fn.stuck = (opts)->
    class Stuck
      elements: []
      resizing: false # if the update event has been fired from a resize

      constructor: (w, opts)->
        # Memoize for performance
        @window = w
        @body = $("body")

        # Initialize data
        @loadElements()
        @calculateTopOffset()

        # Bind all touch, scroll, and resize events
        @body.on(touchmove: => @update()) if @isIOS()
        @window.scroll((=> @update()))
        @window.resize((=> @resize()))

        # Update all element positions
        @update()
        @

      isIOS: ->
        @_isIOS ||= /(iPad|iPhone|iPod)/g.test(navigator.userAgent)

      resize: ->
        # Update the page
        @resizing = true
        @calculateTopOffset()
        @update()
        return

      loadElements: ->
        # Iterate forward over all .stuck elements
        divs = $(".stuck")
        i = divs.length
        y = 0

        while i--
          # Memoize the jQuery node
          node = divs.eq(y)
          y++

          # Set the flag to check if this div needs to be released
          release = false

          # Start with an empty container (only for release divs)
          container = ''

          # Find all node classes
          classes = node.attr("class").split(/\s+/)

          # Create a spacer
          spacer = $("<div/>")

          # Copy each node class to the spacer
          x = classes.length
          while x--

            # Memoize the current class name
            name = classes[x]

            # Check for the release class
            if name == "release"
              # Flag this div for the release feature
              release = true
              # Find its container
              container = node.closest(".release-container")

            # Don't copy internal class names
            unless (name == "stuck" || name == "release")
              # Copy the current class name
              spacer.addClass(name)

          # Copy the height from the original div onto the spacer, hide the
          # spacer, set its background to nothing, then insert it into the dom
          spacer.height(node.outerHeight())
            .hide()
            .css("background-color", "transparent")
            .insertBefore(node)

          # Memoize the top starting position of the node on the page
          top = node.offset().top - parseInt(node.css('margin-top'))

          # Create an in-memory reference to the node and its properties
          @elements.push
            node:       node      # the div that sticks to the page
            spacer:     spacer    # the div that fills the empty space when the node is fixed
            top:        top       # memoize the top starting position of the node on the page
            top_offset: 0         # how much to push this element down the page for stacking
            fixed:      false     # if this item is stuck or stacked at the top of the page
            release:    release   # if this element has the relase tag
            container:  container # the node container when it is tagged for release
            contained:  false     # if this element is stuck at the bottom of its container
        return

      calculateTopOffset: ->
        # The collision / stacking matrix of elements
        matrix = []

        # Iterate forward over all elements
        i = @elements.length
        x = 0

        while i--
          el = @elements[x]
          x++

          # If the matrix is empty
          y = matrix.length
          if y == 0
            # push the element into the matrix as the first row
            # don't stack elements that will be released
            matrix.push([el]) unless el.release

          else
            # The matrix is not empty
            collide_flag = false

            # iterate backwards over the matrix rows while there isn't a collision
            while y-- && !collide_flag
              # reset for each row
              max_height = 0

              # Memoize the elements in this row
              elements = matrix[y]

              # Iterate over each element in this row
              z = elements.length
              while z--
                row_element = elements[z]

                # check for collision
                collision = @collide(row_element.node, el.node)

                if collision
                  # Calculate how much this collision pushes the element down
                  value = row_element.top_offset + row_element.node.outerHeight(true)

                  # Only use the max height for all collisions of a row
                  max_height = value if value > max_height

                  # There can be one or more height collisions, so we set a flag
                  # and take action below, after iterating on all elements in the row
                  collide_flag = true

                  # Can we go to the next matrix row?
                  if matrix[y+1]?
                    # This element belongs in the next row: matrix[y+1].push(el)
                    collide_y = y + 1
                  else
                    # This is the last row, so create a new row: matrix.push([el])
                    collide_y = -1
                else
                  # No collision
                  if y == 0
                    # This is the first row, put it here: matrix[y].push(el)
                    collide_y = 0

            # Check if there has been a collision in this row
            if collide_flag
              # Set this elements offset
              el.top_offset = max_height
              # Don't stack elements that will be released
              unless el.release
                # If we have a row number, insert it
                if collide_y >= 0
                  matrix[collide_y].push(el)
                else
                  # If there is no row number (-1), create a row
                  matrix.push([el])
            else
              # No collision, reset the top offset
              el.top_offset = 0
              # Push this item into the first row
              matrix[0].push(el) unless el.release
        return

      collide: (node1, node2)->
        n1l = node1.offset().left
        n2l = node2.offset().left

        # If node1 is left aligned with node2
        if n1l == n2l
          true # overlap

        # If node1 is to the left of node2
        else if n1l < n2l
          # Check for overlap
          if Math.floor(n1l) + node1.width() > Math.ceil(n2l) then true else false

        # Node1 is to the right of node2
        else
          # Check for overlap
          if Math.floor(n2l) + node2.width() > Math.ceil(n1l) then true else false

      update: ->
        # Find the scroll position
        window_top = @window.scrollTop()

        # Iterate through all elements
        i = @elements.length
        while i--
          # Memoize the current element
          el = @elements[i]

          # If this is a resize event
          if @resizing
            # Compute where the element top should be on the page
            if el.fixed
              el.top = el.spacer.offset().top - parseInt(el.spacer.css('margin-top'))
            else
              el.top = el.node.offset().top - parseInt(el.node.css('margin-top'))

            # If the element is fixed
            if el.fixed
              # Update it's left and width css positions
              el.node.css
                top:  el.top_offset
                left:  el.spacer.offset().left
                width: el.spacer.outerWidth()

            # If the element is contained and the window is scrolled past the bottom of the release container
            if el.contained && window_top > (el.container.offset().top + el.container.height() - el.node.height() - el.top_offset)
              # Apply the css to put the node at the bottom of the container
              el.node.css
                position:  "absolute"
                top:       el.container.height() - el.node.height()
                left:      ''
                width:     ''
                "z-index": ''

          # If the element is fixed, has the release tag, is not contained, and
          # the window is scrolled past the bottom of the release container
          if el.fixed && el.release && !el.contained && window_top > (el.container.offset().top + el.container.height() - el.node.height() - el.top_offset)
            # Make the element contained
            el.contained = true

            # Make the container relative position
            el.container.css("position", "relative")

            # Apply the css to put the node at the bottom of the container
            el.node.css
              position:  "absolute"
              top:       el.container.height() - el.node.height()
              left:      ''
              width:     ''
              "z-index": ''

          # If the element has been contained and the window is scrolled back
          # above the bottom of the release container
          if el.contained && window_top < (el.container.offset().top + el.container.height() - el.node.height() - el.top_offset)
            # The element is no longer contained
            el.contained = false

            # The container no longer needs to be in relative position
            el.container.css("position", '')

            # Apply the css to fix it to the top or make it stacked
            el.node.css
              position:  "fixed"
              top:       el.top_offset
              left:      el.spacer.offset().left
              width:     el.spacer.outerWidth()
              "z-index": 999

          # If the element is not fixed and the window is scrolled past its stacked position
          if !el.fixed && window_top > el.top - el.top_offset
            # Make the element fixed
            el.fixed = true

            # Show its spacer
            el.spacer.show()

            # Apply the css to fix it to the top or make it stacked
            el.node.css
              position:  "fixed"
              top:       el.top_offset
              left:      el.spacer.offset().left
              width:     el.spacer.outerWidth()
              "z-index": 999

          # If the element is fixed and the window is scrolled back above its position
          if el.fixed && window_top < el.top - el.top_offset
            # Unfix the element
            el.fixed = false

            # Hide the spacer
            el.spacer.hide()

            # Reset the css values to make the div jump back into the page
            el.node.css
              position:  "relative"
              top:       ''
              left:      ''
              width:     ''
              "z-index": ''

        @resizing = false
        return

      destroy: ->
        # Remove all added spacers
        i = @elements.length
        @elements[i].spacer.remove() while i--

        # Unbind the scroll event
        @window.unbind('scroll')

        # Unbind the resize event
        @window.unbind('resize')

        # Empty all class variables
        @window = @elements = null
        return


    new Stuck(@, opts)

) jQuery