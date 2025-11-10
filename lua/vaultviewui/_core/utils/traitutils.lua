local TraitUtils = {}

--- Apply a trait to a class.
-- Copies all keys from the trait into the class table, without overwriting existing methods.
function TraitUtils.apply(class, trait)
    for k, v in pairs(trait) do
        if class[k] == nil then
            class[k] = v
        end
    end
end

return TraitUtils
