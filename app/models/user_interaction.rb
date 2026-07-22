class UserInteraction < ApplicationRecord
  belongs_to :from_user, class_name: "User"
  belongs_to :to_user, class_name: "User"

  # Enums for interaction types
  enum interaction_type: { interested: "interested", shortlist: "shortlist", noted: "noted", rejected: "rejected" }
  enum status: { pending: "pending", accepted: "accepted", declined: "declined" }

  # Validations
  validates :from_user_id, :to_user_id, presence: true
  validates :interaction_type, presence: true, inclusion: { in: interaction_types.keys }
  validates :from_user_id, uniqueness: { scope: :to_user_id, message: "can only have one interaction per user pair" }
  validate :cannot_interact_with_same_user
  validate :cannot_interact_with_same_gender

  private

  def cannot_interact_with_same_user
    if from_user_id == to_user_id
      errors.add(:to_user_id, "cannot express interest in yourself")
    end
  end

  def cannot_interact_with_same_gender
    if from_user && to_user && from_user.gender == to_user.gender
      errors.add(:to_user_id, "you can only interact with opposite gender")
    end
  end
end
