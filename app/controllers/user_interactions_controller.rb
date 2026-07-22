class UserInteractionsController < ApplicationController
  before_action :require_login
  before_action :set_to_user, except: [ :sent_interests, :received_interests, :shortlisted, :accept_interest, :decline_interest ]

  def express_interest
    @interaction = current_user.sent_interactions.build(
      to_user: @to_user,
      interaction_type: "interested",
      status: "pending"
    )

    if @interaction.save
      flash[:notice] = "Interest expressed successfully! #{@to_user.first_name} will be notified."
      redirect_to user_path(@to_user)
    else
      flash[:alert] = @interaction.errors.full_messages.join(", ")
      redirect_to user_path(@to_user)
    end
  end

  def shortlist
    @interaction = current_user.sent_interactions.build(
      to_user: @to_user,
      interaction_type: "shortlist",
      status: "pending"
    )

    if @interaction.save
      flash[:notice] = "Profile added to shortlist!"
      redirect_to user_path(@to_user)
    else
      flash[:alert] = @interaction.errors.full_messages.join(", ")
      redirect_to user_path(@to_user)
    end
  end

  def add_notes
    @interaction = find_or_create_interaction
    @interaction.notes = params[:notes]
    @interaction.interaction_type = "noted" if @interaction.interaction_type == "interested"

    if @interaction.save
      flash[:notice] = "Notes saved successfully!"
      redirect_to user_path(@to_user)
    else
      flash[:alert] = "Error saving notes"
      redirect_to user_path(@to_user)
    end
  end

  def reject
    @interaction = find_or_create_interaction
    @interaction.interaction_type = "rejected"
    @interaction.status = "declined"

    if @interaction.save
      flash[:notice] = "Profile marked as not interested"
      redirect_to user_path(@to_user)
    else
      flash[:alert] = "Error updating preference"
      redirect_to user_path(@to_user)
    end
  end

  def sent_interests
    @interactions = current_user.sent_interactions.where(interaction_type: "interested").includes(:to_user)
  end

  def received_interests
    @interactions = current_user.received_interactions.where(interaction_type: "interested").includes(:from_user)
  end

  def shortlisted
    @interactions = current_user.sent_interactions.where(interaction_type: "shortlist").includes(:to_user)
  end

  def accept_interest
    @interaction = current_user.received_interactions.find(params[:id])
    @interaction.status = "accepted"

    if @interaction.save
      flash[:notice] = "You've accepted #{@interaction.from_user.first_name}'s interest!"
      redirect_to received_interests_path
    else
      flash[:alert] = "Error accepting interest"
      redirect_to received_interests_path
    end
  end

  def decline_interest
    @interaction = current_user.received_interactions.find(params[:id])
    @interaction.status = "declined"

    if @interaction.save
      flash[:notice] = "Interest declined"
      redirect_to received_interests_path
    else
      flash[:alert] = "Error declining interest"
      redirect_to received_interests_path
    end
  end

  private

  def set_to_user
    @to_user = User.find(params[:id])
  end

  def find_or_create_interaction
    current_user.sent_interactions.find_or_create_by(to_user: @to_user)
  end
end
