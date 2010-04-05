# Adds method arguments detection to ObjInfo

# @todo document!

module Drx

  class ObjInfo

    class << self
      attr_accessor :use_rubyparser
    end

    # Returns a Ruby 1.9.2-compatible array describing the arguments a method expects.
    def method_arguments(method_name)
      if ObjInfo.use_rubyparser
        _method_arguments__by_rubyparser(method_name) || _method_arguments__by_arity(method_name)
      else
        _method_arguments__by_methopara(method_name) || _method_arguments__by_arity(method_name)
      end
    end

    # Strategy: use RubyParser, via the 'arguments' gem.
    # pros: shows default values; works for 1.8 too.
    # cons: very slow.
    def _method_arguments__by_rubyparser(method_name)
      @@once__rubyparser ||= begin
        require 'arguments' rescue nil
        1
      end
      return nil if not defined? Arguments
      args = Arguments.names(the_object, method_name, false)
      return args.map do |arg|
        if arg.size == 2
          [:opt, arg[0], arg[1]]
        else
          name = arg[0].to_s
          case name[0,1]
          when '*' then [:rest, name[1..-1]]
          when '&' then [:block, name[1..-1]]
          else [:req, name]
          end
        end
      end
    rescue SyntaxError => e
      raise
    rescue Exception
      nil
    end

    # Strategy: use Method#parameter (for ruby 1.9 only).
    # pros: fast.
    # cons: doesn't show default values.
    def _method_arguments__by_methopara(method_name)
      @@once__methopara ||= begin
        # For ruby 1.9.0 and 1.9.1, we need to use a gem.
        require 'methopara' rescue nil
        1
      end
      method = the_object.instance_method(method_name)
      if method.respond_to? :parameters
        return method.parameters
      end
    rescue NotImplementedError
      # For some methods #parameters raises an exception. We return nil
      # to move on to the next scheme.
      return nil
    end

    # Strategy: simulation via Method#arity.
    # pros: fast; work without any gems.
    # cons: doesn't show argument names.
    def _method_arguments__by_arity(method_name)
      method = the_object.instance_method(method_name)
      ary, rest = method.arity, false
      if ary < 0
        ary = -ary - 1
        rest = true
      end
      args = [[:req]] * ary
      args << [:rest] if rest
      return args
    end

  end

end
