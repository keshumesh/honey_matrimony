module Api
  module V1
    class UserInteractionsController < ApplicationController
      before_action :set_interaction, only: [:accept, :decline]

      def create
        @interaction = current_user.sent_interactions.new(interaction_params)
        
        if @interaction.save
          render json: {
            message: 'Interaction created successfully',
            interaction: serialize_interaction(@interaction)
          }, status: :created
        else
          render json: { errors: @interaction.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def sent
        @interactions = current_user.sent_interactions.includes(:to_user)
        render json: @interactions.map { |i| serialize_interaction_with_user(i) }, status: :ok
      end

      def received
        @interactions = current_user.received_interactions
                                    .where(interaction_type: 'interested')
                                    .includes(:from_user)
        render json: @interactions.map { |i| serialize_interaction_with_user(i, :from_user) }, status: :ok
      end

      def shortlist
        @interactions = current_user.sent_interactions
                                    .where(interaction_type: 'shortlist')
                                    .includes(:to_user)
        render json: @interactions.map { |i| serialize_interaction_with_user(i) }, status: :ok
      end

      def accept
        @interaction.update(status: 'accepted')
        render json: {
          message: 'Interest accepted',
          interaction: serialize_interaction(@interaction)
        }, status: :ok
      end

      def decline
        @interaction.update(status: 'declined')
        render json: {
          message: 'Interest declined',
          interaction: serialize_interaction(@interaction)
        }, status: :ok
      end

      private

      def set_interaction
        @interaction = UserInteraction.find(params[:id])
        authorize_interaction_user!
      end

      def interaction_params
        params.require(:user_interaction).permit(:to_user_id, :interaction_type, :notes)
      end

      def authorize_interaction_user!
        unless @interaction.from_user == current_user || @interaction.to_user == current_user
          render json: { error: 'Unauthorized' }, status: :unauthorized
        end
      end

      def serialize_interaction(interaction)
        {
          id: interaction.id,
          from_user_id: interaction.from_user_id,
          to_user_id: interaction.to_user_id,
          interaction_type: interaction.interaction_type,
          status: interaction.status,
          notes: interaction.notes,
          created_at: interaction.created_at
        }
      end

      def serialize_interaction_with_user(interaction, user_key = :to_user)
        user = interaction.send(user_key)
        {
          id: interaction.id,
          interaction_type: interaction.interaction_type,
          status: interaction.status,
          notes: interaction.notes,
          user: {
            id: user.id,
            first_name: user.first_name,
            last_name: user.last_name,
            age: calculate_age(user.dob),
            gender: user.gender,
            religion: user.religion,
            height: user.height,
            avatar: user.avatar&.url
          },
          created_at: interaction.created_at
        }
      end

      def calculate_age(dob)
        return nil unless dob
        ((Time.zone.now - dob.to_time) / 1.year.seconds).floor
      end
    end
  end
end
