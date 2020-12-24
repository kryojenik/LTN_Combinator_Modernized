function get_player_data(player_index)
    if global.player_data == nil then
      global.player_data = {}
    end
    local player = game.players[player_index]
    if (player and player.valid) then
      if not global.player_data[player_index] then
        global.player_data[player_index] = {}
      end
      return global.player_data[player_index]
    end
  end