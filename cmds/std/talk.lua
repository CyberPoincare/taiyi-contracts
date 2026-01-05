function talk(someone, something)
    local nfa_me = nfa_helper:get_info()
    assert(nfa_me.data.is_actor == true, "只有角色才能调用talk")

    assert(type(someone) == "string", '谈话对象参数无效')
    assert(someone ~= "", "你得指定和谁谈话")
    assert(type(something) == "string", '谈话内容参数无效')
    assert(something ~= "", "总得说点什么吧")

    assert(contract_helper:is_actor_valid_by_name(someone), "找不到谈话目标")

    local nfa_target = contract_helper:get_actor_info_by_name(someone)
    assert(nfa_target.nfa_id ~= nfa_me.id, "不能和自己谈话")

    local actor_me = contract_helper:get_actor_info(nfa_me.id)
    assert(actor_me.location == nfa_target.location, "不能和不在同一地点的人谈话")

    nfa_helper:talk_to_actor(someone, something)
end

-- 标准谈话回调函数
function on_talking(someone, something)
    local nfa_me = nfa_helper:get_info()
    local actor_me = contract_helper:get_actor_info(nfa_me.id)
    local attributes_me = contract_helper:get_actor_core_attributes(nfa_me.id)

    local actor_target = contract_helper:get_actor_info_by_name(someone)
    local attributes_target = contract_helper:get_actor_core_attributes(actor_target.nfa_id)

    -- 好感提升 = 基础值 × 立场系数
    --  基础值 = 10 + 角色魅力/10 + 角色名誉，最低为10
    --  双方处世立场的关系决定立场系数，并触发不同的对话：
    --  若双方立场相同，立场系数 = 4
    --  若一方立场为仁善或刚正，另一方为叛逆或唯我，立场系数 = 1
    --  否则，立场系数 = 2
    local delta_favor_base = math.max(10, 10 + math.floor(attributes_me.charm / 10))
    local standpoint_dt = math.abs(actor_target.standpoint - actor_me.standpoint)
    local standpoint_fac = 2
    if standpoint_dt < 100 then
        standpoint_fac = 4
    elseif standpoint_dt > 500 then
        standpoint_fac = 1
    end

    local delta_favor = delta_favor_base * standpoint_fac
    local relation = nfa_helper:get_actor_relation_info(someone)
    local favor = math.min(30000, relation.favor + delta_favor);
    nfa_helper:modify_actor_relation_values(someone, { favor = favor })

    contract_helper:narrate(string.format('&YEL&%s&NOR&对&YEL&%s&NOR&说道：%s', actor_me.name, someone, something), true)
    contract_helper:narrate(string.format('&YEL&%s&NOR&对&YEL&%s&NOR&的好感度改变了&GRN&%d&NOR&', actor_me.name, someone, delta_favor), true)
end

-- 标准听话回调函数
function on_listening(from_who, something)
    local nfa_me = nfa_helper:get_info()
    local actor_me = contract_helper:get_actor_info(nfa_me.id)
    local attributes_me = contract_helper:get_actor_core_attributes(nfa_me.id)

    local actor_from = contract_helper:get_actor_info_by_name(from_who)
    local attributes_from = contract_helper:get_actor_core_attributes(actor_from.nfa_id)

    -- 好感提升 = 基础值 × 立场系数
    --  基础值 = 10 + 角色魅力/10 + 角色名誉，最低为10
    --  双方处世立场的关系决定立场系数，并触发不同的对话：
    --  若双方立场相同，立场系数 = 4
    --  若一方立场为仁善或刚正，另一方为叛逆或唯我，立场系数 = 1
    --  否则，立场系数 = 2
    local delta_favor_base = math.max(10, 10 + math.floor(attributes_me.charm / 10))
    local standpoint_dt = math.abs(actor_from.standpoint - actor_me.standpoint)
    local standpoint_fac = 2
    local talk_content = "如此……这般……或许……也不尽然……"
    if standpoint_dt < 100 then
        standpoint_fac = 4
        talk_content = "如此……这般……不错……不错……正是如此！"
    elseif standpoint_dt > 500 then
        standpoint_fac = 1
        talk_content = "如此……这般……不然……不然……岂有此理！？"
    end

    local delta_favor = delta_favor_base * standpoint_fac
    local relation = nfa_helper:get_actor_relation_info(from_who)
    local favor = math.min(30000, relation.favor + delta_favor);
    nfa_helper:modify_actor_relation_values(from_who, { favor = favor })

    contract_helper:narrate(string.format('&YEL&%s&NOR&对&YEL&%s&NOR&说道：%s', actor_me.name, from_who, talk_content), true)
    contract_helper:narrate(string.format('&YEL&%s&NOR&对&YEL&%s&NOR&的好感度改变了&GRN&%d&NOR&', actor_me.name, from_who, delta_favor), true)
end