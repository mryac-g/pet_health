class BackfillDefaultMealUnits < ActiveRecord::Migration[7.1]
  def up
    User.find_each do |user|
      User::DEFAULT_MEAL_UNIT_NAMES.each { |name| user.meal_units.find_or_create_by!(name: name) }
    end
  end

  def down
    MealUnit.where(name: User::DEFAULT_MEAL_UNIT_NAMES).destroy_all
  end
end
