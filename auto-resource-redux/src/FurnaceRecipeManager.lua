local FurnaceRecipeManager = {}

function FurnaceRecipeManager.get_recipe_label(recipe)
  local proto = recipe.prototype
  local main_product = proto.main_product
  local label = {}
  if main_product then
    local fmt = (main_product.type == "item") and "[item=%s] %s" or "[fluid=%s] %s"
    table.insert(label, fmt:format(main_product.name, recipe.name))
  else
    table.insert(label, recipe.name)
  end
  table.insert(label, ("(%s)"):format(recipe.category))
  return table.concat(label, " ")
end

local function clear_pending_recipe(entity)
  local id = entity.unit_number
  local recipe_data = global.furnace_recipes[id]
  if recipe_data then
    for _, mark_id in ipairs(recipe_data.marks) do
      rendering.destroy(mark_id)
    end
  end

  global.furnace_recipes[id] = nil
end

function FurnaceRecipeManager.get_recipe(entity)
  local current_recipe = entity.get_recipe() or entity.previous_recipe
  local recipe_data = global.furnace_recipes[entity.unit_number]
  if not recipe_data then
    return current_recipe, false
  end

  local target_recipe = recipe_data.recipe
  -- can no longer switch, or successfully switched
  if not target_recipe.valid or (current_recipe and current_recipe.name == target_recipe.name) then
    clear_pending_recipe(entity)
    return current_recipe, false
  end

  -- only switch recipe if productivity bar is about to reset (or has just reset) so we don't lose progress
  local bonus_progress = entity.bonus_progress
  if entity.is_crafting() then
    bonus_progress = bonus_progress + (1 - entity.crafting_progress) * entity.productivity_bonus
  end
  if bonus_progress <= 0.01 or bonus_progress >= 0.999 then
    return target_recipe, true
  end

  return current_recipe, false
end

function FurnaceRecipeManager.set_recipe(entity, recipe)
  if global.furnace_recipes[entity.unit_number] then
    clear_pending_recipe(entity)
  end
  local offset = { 0, -1.1 }
  local bg = rendering.draw_sprite({
    sprite = "utility/entity_info_dark_background",
    render_layer = "selection-box",
    target = entity,
    target_offset = offset,
    forces = { entity.force },
    surface = entity.surface,
    only_in_alt_mode = true
  })
  local arrows = rendering.draw_sprite({
    sprite = "arr-changing-icon",
    render_layer = "selection-box",
    target = entity,
    target_offset = offset,
    forces = { entity.force },
    surface = entity.surface,
    only_in_alt_mode = true,
  })
  local main_product = recipe.prototype.main_product
  local recipe_icon = nil
  if main_product then
    recipe_icon = rendering.draw_sprite({
      sprite = (main_product.type == "item" and "item/" or "fluid/") .. main_product.name,
      render_layer = "selection-box",
      target = entity,
      target_offset = offset,
      forces = { entity.force },
      surface = entity.surface,
      only_in_alt_mode = true,
    })
  end

  global.furnace_recipes[entity.unit_number] = {
    recipe = recipe,
    marks = { bg, arrows, recipe_icon }
  }
end

function FurnaceRecipeManager.initialise()
  if global.furnace_recipes == nil then
    global.furnace_recipes = {}
  end
end

return FurnaceRecipeManager