-- ==========================================
-- PERBAIKAN PENCARIAN BAGIAN POHON (ANTI-ERROR)
-- ==========================================

task.spawn(function()
    while task.wait(0.2) do
        if getgenv().W424.ChopAura then
            pcall(function()
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                local tool, damageID = getAnyTool() -- Menggunakan fungsi tool yang sudah ada
                
                -- Memindai Workspace langsung (karena pohon besar ada di Workspace, bukan cuma di Foliage)
                for _, tree in ipairs(Workspace:GetChildren()) do
                    if not getgenv().W424.ChopAura then break end
                    
                    -- Deteksi apakah objek tersebut adalah pohon (berdasarkan nama)
                    if tree:IsA("Model") and (tree.Name:find("Tree") or tree.Name:find("Log")) then
                        
                        -- Ambil bagian fisik secara aman tanpa harus mencari "Trunk"
                        local part = tree.PrimaryPart or tree:FindFirstChildWhichIsA("BasePart")
                        
                        if part and (part.Position - hrp.Position).Magnitude <= getgenv().W424.ChopRadius then
                            
                            -- 1. Kirim Damage Server agar Log / Item Drop muncul
                            local damageRemote = RemotesFolder:FindFirstChild("ToolDamageObject")
                            if damageRemote and tool and damageID then
                                damageRemote:InvokeServer(
                                    tree,
                                    tool,
                                    damageID,
                                    CFrame.new(part.Position, hrp.Position)
                                )
                            end
                            
                            -- 2. Kirim Destroy Signal agar pohon langsung hancur bersih
                            local destroyEvent = RemotesFolder:FindFirstChild("DestroyObject")
                            if destroyEvent and firesignal then
                                firesignal(destroyEvent.OnClientEvent, tree, part.CFrame)
                            end
                            
                            task.wait(0.05)
                        end
                    end
                end
            end)
        end
    end
end)
