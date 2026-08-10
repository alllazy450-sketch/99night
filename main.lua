-- ==========================================
-- W424 HUB | v5.7.1 (DEBUGGED & STABILIZED)
-- ==========================================

-- ... (Bagian atas script, Kairo, core functions sampai reliableDragItemToPos TETAP SAMA) ...

-- BAGIAN ITEM TP YANG DIPERBAIKI (Ganti blok ini di script kamu):
for catName, listItems in pairs(itemCategories) do
    selectedItems[catName] = listItems[1]
    -- PENTING: Gunakan .. untuk penggabungan string, bukan +
    Window:AddDropdown(ItemTPTab, catName:gsub("_", " "), "Pilih item", listItems, false, listItems[1], function(value) selectedItems[catName] = value end, "TP_" .. catName)
    
    Window:AddButton(ItemTPTab, "Bring " .. catName:gsub("_", " "), "Tarik semua item", "rbxassetid://16932740082", function()
        local hrp = getRootPart()
        if not hrp then return end
        local selected = selectedItems[catName]
        local count = 0
        local allItems = ItemsFolder:GetDescendants()
        local toProcess = {}
        for _, item in ipairs(allItems) do
            if item.Name:match(selected) and (item:IsA("Model") or item:IsA("Tool") or item:IsA("BasePart")) then
                table.insert(toProcess, item)
            end
        end
        
        local basePos = hrp.Position
        for i, item in ipairs(toProcess) do
            -- MEMAKSA SEMUA MENJADI ANGKA (TONUMBER) UNTUK MENGHINDARI ERROR ARITMATIKA
            local c = tonumber(count) or 0
            local angle = c * (math.pi * 2 / 8) 
            local radius = 3 + math.floor(c / 8) * 1.5 
            local xOffset = math.cos(angle) * radius
            local zOffset = math.sin(angle) * radius
            
            local tpPos = basePos + Vector3.new(tonumber(xOffset), 1, tonumber(zOffset))
            
            task.spawn(function() reliableDragItemToPos(item, tpPos) end)
            count = c + 1
            if i % 3 == 0 then task.wait(0.1) end 
        end
        Window:Notify({Title = "Success", Description = "Item TP", Content = "Berhasil menarik " .. count .. "x " .. selected, Color = Color3.fromRGB(10, 30, 60), Delay = 3})
    end)
    Window:AddDivider(ItemTPTab, "")
end

-- ... (Mr.al W424HUB) ...
