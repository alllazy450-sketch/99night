-- =============================================
-- AURA CHOP LOOP (CRASH-PROOF & CLEAN)
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
                
                -- AURA CHOP (Trees - Safely bypassing animation script errors)
                if treeAuraEnabled then
                    local map = Workspace:FindFirstChild("Map")
                    if map then
                        local foliage = map:FindFirstChild("Foliage") or map
                        for _, obj in ipairs(foliage:GetDescendants()) do
                            if obj:IsA("Model") and obj.Parent then
                                -- Cari part fisik utama pohon secara aman tanpa memicu script animasi yang rusak
                                local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                                
                                if part and (part.Position - hrp.Position).Magnitude <= auraRadius then
                                    task.spawn(function()
                                        -- Kirim suara tebasan
                                        pcall(function()
                                            RemoteEvents.RequestReplicateSound:FireServer("FireAllClients", "WoodChop", {
                                                Instance = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head"),
                                                Volume = 0.4
                                            })
                                        end)
                                        
                                        -- Kirim damage dengan aman langsung ke part fisik pohon
                                        RemoteEvents.ToolDamageObject:InvokeServer(obj, tool, damageID, CFrame.new(part.Position), true)
                                    end)
                                    task.wait(0.3) -- Jeda agar animasi game sempat memproses tanpa error
                                end
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.6)
    end
end)
