    module.exports = (seem = require 'seem') ->
      is_generator = (f) ->
        f? and f.next? and f.throw?

Detect whether a function is a generator function, and if it is, memoize the generator version.

      seemify = (f,ctx,args) ->
        return unless f?

Use the memoized generator if present.

        if f.__generator?
          return f.__generator.apply ctx, args

        v = f.apply ctx, args

If the outcome of the function call is a generator, the function was a generator function, we better memoize it.

        if is_generator v
          f.__generator = seem f
        if f.__generator?
          return f.__generator.apply ctx, args

        v
