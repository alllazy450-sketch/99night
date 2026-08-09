-- ==========================================
-- FUNGSI TELEPORT ITEM YANG LEBIH KUAT
-- ==========================================
local function teleportItemToPos(item, targetPos, maxRetries)
    maxRetries = maxRetries or 3
    if not item or not item:IsDescendantOf(workspace) then return false end
    
    local part = findValidPart(item)
    if not part then return false end

    -- Daftar remote yang mungkin digunakan
    local remoteCandidates = {
        RemoteEvents:FindFirstChild("RequestStartDraggingItem"),
        RemoteEvents:FindFirstChild("RequestPickupItem"),
        RemoteEvents:FindFirstChild("RequestGrabItem"),
        RemoteEvents:FindFirstChild("RequestPlaceItem"),
        RemoteEvents:FindFirstChild("DropItem"),
    }

    local success = false
    for attempt = 1, maxRetries do
        if not item:IsDescendantOf(workspace) then break end

        -- 1. Coba kirim remote drag jika ada
        local dragStarted = false
        for _, remote in ipairs(remoteCandidates) do
            if remote then
                pcall(function()
                    remote:FireServer(item)
                    dragStarted = true
                end)
                if dragStarted then break end
            end
        end

        task.wait(0.05)

        -- 2. Paksa posisi CFrame
        if item:IsA("Model") and item.PrimaryPart then
            item:SetPrimaryPartCFrame(CFrame.new(targetPos))
        else
            part.CFrame = CFrame.new(targetPos)
        end

        task.wait(0.05)

        -- 3. Kirim remote stop drag (jika ada)
        local stopRemote = RemoteEvents:FindFirstChild("StopDraggingItem")
        if stopRemote then
            pcall(function() stopRemote:FireServer(item) end)
        end

        -- 4. Verifikasi posisi (opsional)
        task.wait(0.1)
        local currentPos = (item:IsA("Model") and item.PrimaryPart) and item.PrimaryPart.Position or part.Position
        if (currentPos - targetPos).Magnitude < 1.5 then
            success = true
            break
        else
            -- Jika gagal, coba lagi dengan jeda lebih lama
            task.wait(0.3)
        end
    end

    return success
end

-- ==========================================
-- PERBAIKAN PADA LOOP AUTO BRING
-- ==========================================
-- Ganti pemanggilan dragItemToPos dengan teleportItemToPos

-- Di dalam loop continuous bring (sekitar baris 202):
task.spawn(function()
    while ScriptRunning do
        if continuousBringEnabled then
            local hrp = getRootPart()
            if hrp then
                local count = 0
                for _, item in ipairs(ItemsFolder:GetDescendants()) do
                    if item.Name == selectedBringItem and (item:IsA("Model") or item:IsA("Tool") or item:IsA("BasePart")) then
                        -- Posisi target dengan offset per item
                        local targetPos = hrp.Position + (hrp.CFrame.LookVector * 5) + Vector3.new(0, 3 + (count * 1.5), 0)
                        teleportItemToPos(item, targetPos, 3)  -- maks 3 percobaan
                        count = count + 1
                        task.wait(0.05)  -- jeda lebih cepat
                    end
                end
            end
        end
        task.wait(1.0)  -- cek spawn baru setiap 1 detik (lebih responsif)
    end
end)

-- Juga perbaiki fungsi untuk Auto Machine Grind dan Auto Cook (sekitar baris 150-160)
-- Ganti dragItemToPos dengan teleportItemToPos di sana juga.