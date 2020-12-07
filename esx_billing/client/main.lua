ESX = nil
local isDead = false
local hasAccepted = false

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
end)

function ShowBillsMenu()
	ESX.TriggerServerCallback('esx_billing:getBills', function(bills)
		if #bills > 0 then
			ESX.UI.Menu.CloseAll()
			local elements = {}

			for k,v in ipairs(bills) do
				table.insert(elements, {
					label  = ('%s - <span style="color:red;">%s</span>'):format(v.label, _U('invoices_item', ESX.Math.GroupDigits(v.amount))),
					billId = v.id
				})
			end

			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'billing', {
				title    = _U('invoices'),
				align    = 'bottom-right',
				elements = elements
			}, function(data, menu)
				menu.close()

				ESX.TriggerServerCallback('esx_billing:payBill', function()
					ShowBillsMenu()
				end, data.current.billId)
			end, function(data, menu)
				menu.close()
			end)
		else
			ESX.ShowNotification(_U('no_invoices'))
		end
	end)
end

RegisterCommand('showbills', function()
	if not isDead and not ESX.UI.Menu.IsOpen('default', GetCurrentResourceName(), 'billing') then
		ShowBillsMenu()
	end
end, false)

RegisterKeyMapping('showbills', _U('keymap_showbills'), 'keyboard', 'F7')

AddEventHandler('esx:onPlayerDeath', function() isDead = true end)
AddEventHandler('esx:onPlayerSpawn', function(spawn) isDead = false end)

-- @author RumDum
-- event that handles the opening of the confirmation menu
RegisterNetEvent('esx_billing:openConfirmation')
AddEventHandler('esx_billing:openConfirmation', function(src, playerId, sharedAccountName, label, amount)

	TriggerEvent('esx:showHelpNotification', src, 'Billing is now pending...')

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'billing_confirm', {
		title = _U('confirmation_title'),
		align = 'center',
		elements = {
			{label = _U('confirmation_accept'),  value = 'yes'},
			{label = _U('confirmation_deny'), value = 'no'}
		}
	}, function(data2, menu2)
		if data2.current.value == 'yes' then
			-- accept bill
			hasAccepted = true
			TriggerServerEvent('esx_billing:sendConfirmedBill', playerId, sharedAccountName, label, amount)
			ESX.ShowNotification(_U('target_accept'), true, false, 140)
			TriggerServerEvent('esx_billing:notify', src, _U('source_accept'))
			-- always close the menu after our tasks are done (prevent glitching)
			ESX.UI.Menu.CloseAll()
		elseif data2.current.value == 'no' then
			-- cancel bill
			ESX.ShowNotification(_U('target_decline'), true, false, 140)
			TriggerServerEvent('esx_billing:notify', src, _U('source_decline'))
			-- always close the menu after our tasks are done (prevent glitching)
			ESX.UI.Menu.CloseAll()
	  	end
	end)
end)


-- Uploaded by toxic