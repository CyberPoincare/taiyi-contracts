welcome = { consequence = false }
look = { consequence = false }
view = { consequence = false }
inventory = { consequence = false }
hp = { consequence = false }
resource = { consequence = false }
map = { consequence = false }
help = { consequence = false }

go = { consequence = true }
deposit_qi = { consequence = true }
withdraw_qi = { consequence = true }
exploit = { consequence = true }
start_cultivation = { consequence = true }
stop_cultivation = { consequence = true }
eat = { consequence = true }
touch = { consequence = true }
talk = { consequence = true }

function init_data()
    return {
        is_actor = true,
        unit = '个'
    }
end

function get_title()
    return "普通百姓"
end

function eval_help()
    import_contract('contract.help.actors.normal').help();
end

function eval_welcome()
    import_contract('contract.welcome').welcome();
end

function eval_look(target)
    local look = import_contract("contract.cmds.std.look").look
    look(target)
end

function eval_view(target)
    local view = import_contract("contract.cmds.std.view").view
    view(target)
end

function eval_inventory(target, options)
    local inventory = import_contract("contract.cmds.actor.inventory").inventory
    inventory(target, options)
end

function eval_hp(target, option)
    local hp = import_contract("contract.cmds.actor.hpcmd").hp
    hp(target, option)
end

function eval_resource(target, option)
    local resource = import_contract("contract.cmds.actor.resource").resource
    resource(target, option)
end

function eval_map(target)
    local map = import_contract("contract.cmds.std.map").map
    map(target)
end

function check_live()
    local nfa_me = nfa_helper:get_info()
    local actor_me = contract_helper:get_actor_info(nfa_me.id)
    assert(actor_me.health > 0, string.format('&YEL&%s&NOR&已经去世了', actor_me.name))
end

function do_go(dir)
    check_live()
    local go = import_contract("contract.cmds.std.gocmd").go
    go(dir)
end

function do_eat(something)
    check_live()
    local eat = import_contract("contract.cmds.std.eat").eat
    eat(something)
end

function do_exploit(something)
    check_live()
    if something == "" then
        local exploit = import_contract("contract.cmds.std.exploit").exploit
        exploit()
    end
end

function do_start_cultivation()
    local start = import_contract("contract.cmds.std.cultivation").start
    local qi = nfa_helper:get_info().qi / 2
    start(math.floor(qi))
end

function do_stop_cultivation()
    local stop = import_contract("contract.cmds.std.cultivation").stop
    stop()
end

function on_heart_beat()
    base_active()
end

function base_active()
    local nfa_me = nfa_helper:get_info()
    local actor = contract_helper:get_actor_info(nfa_me.id)

    if not actor.born then
        contract_helper:narrate(string.format("&YEL&%s&NOR&还没有出生。", actor.name), true)
        nfa_helper:disable_tick()
        return
    end

    if actor.health <= 0 then
        contract_helper:narrate(string.format("&YEL&%s&NOR&已经去世了。", actor.name), true)
        nfa_helper:disable_tick()
        return
    end

    local tiandao = contract_helper:get_tiandao_property()
    local should_age = tiandao.v_years - actor.born_vyears;

    if actor.age < should_age then
        if tiandao.v_months >= actor.born_vmonths and tiandao.v_days >= actor.born_vdays then
            local age = actor.age + 1;
            nfa_helper:modify_actor_attributes({ age = 1 }, {})
            --process talents
            try_trigger_actor_talents(actor, age);

            if age >= 30 then
                -- healthy down
                nfa_helper:modify_actor_attributes({ health = -1 }, { health = -1 })
            end

            --trigger actor grow
            on_grown()
        end
    end
end

function try_trigger_actor_talents(actor, age)
    local talents = actor.talents
    for i, talent_id in pairs(talents) do
        local trigger_num = nfa_helper:get_actor_talent_trigger_number(talent_id)
        if trigger_num < 1 then
            local talent = contract_helper:get_actor_talent_rule_info(talent_id)
            local talent_contract = import_contract(talent.main_contract)
            if talent_contract.trigger ~= nil then
                talent_contract:trigger()
            end
            nfa_helper:set_actor_talent_trigger_number(talent_id, trigger_num+1)
        end
    end
end

function do_deposit_qi(amount)
    assert(amount > 0, "设置的真气无效")
    nfa_helper:deposit_from(contract_base_info.caller, amount, "QI", true)
end

function do_withdraw_qi(amount)
    assert(amount > 0, "设置的真气无效")

    local nfa = nfa_helper:get_info()
    assert(nfa.qi >= amount, "角色体内真气不足")

    assert(contract_base_info.caller == nfa.owner_account, "无权从角色体内提取真气")
    nfa_helper:withdraw_to(nfa.owner_account, amount, "QI", true)
end

-- 成长回调函数
function on_grown()
    -- local tiandao = contract_helper:get_tiandao_property()
    local nfa_me = nfa_helper:get_info()
    local actor = contract_helper:get_actor_info(nfa_me.id)
    contract_helper:narrate(string.format('&YEL&%s&NOR&成长到&YEL&%d&NOR&岁，健康&YEL&%d&NOR&。', actor.name, actor.age, actor.health), true)
end

function do_touch(target_name)
    local nfa_me = nfa_helper:get_info()
    local actor = contract_helper:get_actor_info(nfa_me.id)
    local inv = contract_helper:list_nfa_inventory(nfa_me.id, "")
    if #inv == 0 then
        contract_helper:narrate(string.format('    &YEL&%s&NOR&没有&YEL&%s&NOR&', actor.name, target_name), false)
    else
        Item = import_contract('contract.inherit.item').Item
        for i, obj in pairs(inv) do
            local item = Item:new(obj)
            local short_name = item:short()
            if target_name == short_name then
                contract_helper:do_nfa_action(obj.id, "touch", {actor.name})
                break
            end
        end
    end
end

function do_talk(someone, something)
    check_live()

    local talk = import_contract("contract.cmds.std.talk").talk
    talk(someone, something)
end

-- 谈话回调函数
function on_actor_talking(someone, something)
    local on_talking = import_contract("contract.cmds.std.talk").on_talking
    on_talking(someone, something)
end

-- 听话回调函数
function on_actor_listening(from_who, something)
    local on_listening = import_contract("contract.cmds.std.talk").on_listening
    on_listening(from_who, something)
end