require 'rails_helper'

RSpec.describe User, type: :model do
  # Associations
  describe 'associations' do
    it { is_expected.to have_secure_password }
  end

  # Validations
  describe 'validations' do
    subject { build(:user) }

    # Validations required for all users
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to validate_presence_of(:password) }
    it { is_expected.to validate_length_of(:password).is_at_least(6) }
    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_presence_of(:mobile_no) }
    it { is_expected.to validate_presence_of(:gender) }

    # Validations required for non-admin users
    describe 'for non-admin users' do
      subject { build(:user, role: 'user') }

      it { is_expected.to validate_presence_of(:last_name) }
      it { is_expected.to validate_presence_of(:dob) }
      it { is_expected.to validate_presence_of(:religion) }
      it { is_expected.to validate_presence_of(:height) }
      it { is_expected.to validate_presence_of(:marital_status) }
      it { is_expected.to validate_presence_of(:complexion) }
      it { is_expected.to validate_presence_of(:mother_tongue) }
    end

    # Validations for admin users (optional matrimony fields)
    describe 'for admin users' do
      subject { build(:user, :admin) }

      it 'allows missing last_name' do
        expect(subject).to be_valid
      end

      it 'allows missing dob' do
        expect(subject).to be_valid
      end

      it 'allows missing religion' do
        expect(subject).to be_valid
      end

      it 'allows missing height' do
        expect(subject).to be_valid
      end

      it 'allows missing marital_status' do
        expect(subject).to be_valid
      end

      it 'allows missing complexion' do
        expect(subject).to be_valid
      end

      it 'allows missing mother_tongue' do
        expect(subject).to be_valid
      end
    end

    context 'email format' do
      it 'accepts valid email' do
        user = build(:user, email: 'test@example.com')
        expect(user).to be_valid
      end

      it 'rejects invalid email' do
        user = build(:user, email: 'invalid-email')
        expect(user).not_to be_valid
      end
    end

    context 'mobile number validation' do
      it 'accepts 10-digit mobile number' do
        user = build(:user, mobile_no: '9876543210')
        expect(user).to be_valid
      end

      it 'rejects mobile number with non-digits' do
        user = build(:user, mobile_no: '98765abc10')
        expect(user).not_to be_valid
      end

      it 'rejects mobile number with less than 10 digits' do
        user = build(:user, mobile_no: '987654321')
        expect(user).not_to be_valid
      end
    end
  end

  # Enums
  describe 'enums' do
    it { is_expected.to define_enum_for(:role).with_values(user: 'user', manager: 'manager', admin: 'admin') }

    it 'defaults role to user' do
      user = create(:user)
      expect(user.role).to eq('user')
    end
  end

  # Role methods
  describe 'role methods' do
    let(:user) { create(:user, role: 'user') }
    let(:manager) { create(:user, role: 'manager') }
    let(:admin) { create(:user, role: 'admin') }

    describe '#admin?' do
      it 'returns true for admin user' do
        expect(admin.admin?).to be true
      end

      it 'returns false for non-admin user' do
        expect(user.admin?).to be false
      end
    end

    describe '#manager?' do
      it 'returns true for manager user' do
        expect(manager.manager?).to be true
      end

      it 'returns false for non-manager user' do
        expect(user.manager?).to be false
      end
    end

    describe '#regular_user?' do
      it 'returns true for regular user' do
        expect(user.regular_user?).to be true
      end

      it 'returns false for non-regular user' do
        expect(admin.regular_user?).to be false
      end
    end
  end

  # Permission methods
  describe 'permission methods' do
    let(:regular_user) { create(:user, role: 'user') }
    let(:manager) { create(:user, role: 'manager') }
    let(:admin) { create(:user, role: 'admin') }
    let(:another_user) { create(:user, role: 'user') }

    describe '#can_manage_users?' do
      it 'returns true for manager' do
        expect(manager.can_manage_users?).to be true
      end

      it 'returns true for admin' do
        expect(admin.can_manage_users?).to be true
      end

      it 'returns false for regular user' do
        expect(regular_user.can_manage_users?).to be false
      end
    end

    describe '#can_edit_user?' do
      it 'allows user to edit own profile' do
        expect(regular_user.can_edit_user?(regular_user)).to be true
      end

      it 'allows admin to edit any user' do
        expect(admin.can_edit_user?(regular_user)).to be true
      end

      it 'allows manager to edit any user' do
        expect(manager.can_edit_user?(regular_user)).to be true
      end

      it 'prevents regular user from editing other users' do
        expect(regular_user.can_edit_user?(another_user)).to be false
      end
    end

    describe '#can_delete_user?' do
      it 'allows user to delete own account' do
        expect(regular_user.can_delete_user?(regular_user)).to be true
      end

      it 'allows admin to delete any user' do
        expect(admin.can_delete_user?(regular_user)).to be true
      end

      it 'prevents regular user from deleting other users' do
        expect(regular_user.can_delete_user?(another_user)).to be false
      end

      it 'prevents manager from deleting users' do
        expect(manager.can_delete_user?(regular_user)).to be false
      end
    end
  end

  # Password encryption
  describe 'password encryption' do
    it 'encrypts password on creation' do
      user = create(:user, password: 'password123')
      expect(user.password_digest).not_to eq('password123')
    end

    it 'authenticates with correct password' do
      user = create(:user, password: 'password123')
      expect(user.authenticate('password123')).to be_truthy
    end

    it 'does not authenticate with incorrect password' do
      user = create(:user, password: 'password123')
      expect(user.authenticate('wrongpassword')).to be_falsey
    end
  end

  # Matrimony profile fields
  describe 'matrimony profile' do
    let(:user) { create(:user) }

    it 'has all matrimony profile fields' do
      expect(user).to respond_to(:profile_for)
      expect(user).to respond_to(:dob)
      expect(user).to respond_to(:height)
      expect(user).to respond_to(:religion)
      expect(user).to respond_to(:caste)
      expect(user).to respond_to(:complexion)
      expect(user).to respond_to(:marital_status)
      expect(user).to respond_to(:mother_tongue)
    end
  end
end
