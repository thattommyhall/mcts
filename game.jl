mutable struct NimState
    just_moved
    chips
end

function clone(state)
    NimState(state.just_moved, copy(state.chips))
end

function flip_player(state)
    player = state.just_moved
    new_player = if player == 0
        1
    else
        0
    end
    state.just_moved = new_player
end

function make_move(state, move)
    stack, count = move
    state.chips[stack] -= count
    flip_player(state)
    state
end

function get_moves(state)
    result = []
    for stack in 1:length(state.chips)
        for count in 1:state.chips[stack]
            push!(result, (stack, count))
        end
    end
    result
end

function ended(state)
    all(state.chips) do (stack)
        stack == 0
    end
end

function get_result(state, just_moved)
    if just_moved == state.just_moved
        1
    else
        0
    end
end

mutable struct Node
    move
    parent
    children
    wins
    visits
    untried_moves
    just_moved
end

Node(move,parent,state) = Node(move,
                               parent,
                               [],
                               0,
                               0,
                               get_moves(state),
                               state.just_moved)

function uct_select_child(node)
    sort(node.children, by=c->c.wins/c.visits + sqrt(2*log(node.visits)/c.visits))[end]
end

function add_child(node, move, state)
    n = Node(move, node, state)
    deleteat!(node.untried_moves, findin(node.untried_moves, [move]))
    push!(node.children, n)
    n
end

function update(node, result)
    node.visits += 1
    node.wins += result
end

function uct(rootstate, itermax)
    rootnode = Node(false, false, rootstate)
    for i in 1:itermax
        node = rootnode
        state = clone(rootstate)

        while node.untried_moves == [] && node.children != []
            node = uct_select_child(node)
            make_move(state, node.move)
        end

        if node.untried_moves != []
            m = rand(node.untried_moves)
            make_move(state, m)
            node = add_child(node, m, state)
        end

        while get_moves(state) != []
            make_move(state, rand(get_moves(state)))
        end

        while node != false
            update(node, get_result(state, node.just_moved))
            node = node.parent
        end
    end

    sort(rootnode.children, by=c->c.visits)[end].move
end

function play_game(init)
    state = init
    println(state)
    while get_moves(state) != []
        if state.just_moved == 0
            m = uct(state, 10000)
        else
            m = uct(state, 10000)
        end
        make_move(state, m)
        println(state)
    end

    if get_result(state, state.just_moved) == 1
        println("$(state.just_moved) won")
    else
        println("MEH")
    end
end

play_game(NimState(1, [10, 15]))
