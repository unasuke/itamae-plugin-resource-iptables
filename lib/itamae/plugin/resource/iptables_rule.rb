require 'itamae/resource/base'

module Itamae
  module Plugin
    module Resource
      class IptablesRule < Itamae::Resource::Base
        define_attribute :chain, type: String, required: true
        define_attribute :table, type: String, default: 'filter'
        define_attribute :protocol, type: String
        define_attribute :source, type: String
        define_attribute :destination, type: String
        define_attribute :jump, type: String
        define_attribute :in_interface, type: String
        define_attribute :out_interface, type: String
        define_attribute :jump, type: String

        define_attribute :sport, type: Fixnum
        define_attribute :dport, type: Fixnum

        define_attribute :state, type: Array

        define_attribute :comment, type: String, default_name: true

        def pre_action
          if attributes.action != :create
            attributes.jump = attributes.action.to_s.upcase
          end
        end

        def set_current_attributes
          super
          rule = build_rule(attributes)
          current.exist = run_command(['iptables', '--table', attributes.table, '--check', attributes.chain] + rule, error: false).exit_status == 0
          unless current.exist
            Logger.info "Create rule for #{attributes.chain}: #{rule.join(' ')}"
          end
        end

        def action_create(options)
          unless current.exist
            rule = build_rule(attributes)
            run_command(['iptables', '--table', attributes.table, '--append', attributes.chain] + rule)
          end
        end

        def action_accept(options)
          action_create(options)
        end

        def action_drop(options)
          action_create(options)
        end

        private

        SIMPLE_RULE_KEYS = %w[
          protocol
          source
          destination
          jump
          in_interface
          out_interface
          sport
          dport
        ]

        def build_rule(attrs)
          rule = []

          SIMPLE_RULE_KEYS.each do |key|
            if attrs.has_key?(key)
              rule << "--#{key.gsub('_', '-')}" << attrs[key]
            end
          end

          if state = attrs['state']
            rule << '--match' << 'state' << '--state' << state.join(',')
          end

          rule << '--match' << 'comment' << '--comment' << attrs['comment']

          rule
        end
      end
    end
  end
end