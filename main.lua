-- =============================================
-- AURA CHOP LOOP (FIXED WITH SOUND & PROPER COOLDOWN)
-- =============================================
task.spawn(function()
    while ScriptRunning do
        if killAuraEnabled or treeAuraEnabled then
            local hrp = getRootPart()
            local tool, damageID = getAnyToolWithDamageID()
            
            if hrp and tool and damageID then
                pcall(function() RemoteEvents.EquipItemHandle:FireServer("FireAllClients", tool) end)
                
                -- KILL AURA (Mobs)
                if killAuraEnabled then
                    local characters = Workspace:FindFirstChild("Characters")
                    if characters then
                        for _, mob in ipairs(characters:GetChildren()) do
                            if mob:IsA("Model") and mob.Parent then
                                local mobHumanoid = mob:FindFirstChildOfClass("Humanoid")
                                if mobHumanoid and mobHumanoid.Health > 0 then
                                    local part = mob.PrimaryPart or mob:FindFirstChildWhichIsA("BasePart")
                                    if part and (part.Position - hrp.Position).Magnitude <= auraRadius then
                                        task.spawn(function()
                                            RemoteEvents.ToolDamageObject:InvokeServer(mob, tool, damageID, CFrame.new(part.Position), true)
                                        end)
                                    end
                                end
                            end
                        end
                    end
                end
                
                -- AURA CHOP (Trees - With Sound & Animation Sync)
                if treeAuraEnabled then
                    local map = Workspace:FindFirstChild("Map")
                    if map then
                        local foliage = map:FindFirstChild("Foliage") or map
                        for _, obj in ipairs(foliage:GetDescendants()) do
                            if obj:IsA("Model") and obj.Parent then
                                -- Pastikan pohon masih memiliki bagian Trunk agar tidak error
                                if not obj:FindFirstChild("Trunk") then
                                    continue
                                end
                                
                                local part = obj.PrimaryPart or obj:FindFirstChild("Trunk") or obj:FindFirstChildWhichIsA("BasePart")
                                if part and (part.Position - hrp.Position).Magnitude <= auraRadius then
                                    task.spawn(function()
                                        -- 1. Kirim suara tebasan agar script animasi pohon mendengarnya
                                        pcall(function()
                                            RemoteEvents.RequestReplicateSound:FireServer("FireAllClients", "WoodChop", {
                                                Instance = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head"),
                                                Volume = 0.4
                                            })
                                        end)
                                        
                                        -- 2. Kirim damage ke pohon
                                        RemoteEvents.ToolDamageObject:InvokeServer(obj, tool, damageID, CFrame.new(part.Position), true)
                                    end)
                                    
                                    -- Jeda kecil agar animasi pohon sempat berjalan natural per pohon
                                    task.wait(0.2)
                                end
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.5) -- Jeda antar loop keseluruhan
    end
end)
