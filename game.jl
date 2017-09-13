module Game

mutable struct NimState
    just_moved::Int64
    chips::Vector{Int64}
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
    result = Tuple{Int64, Int64}[]
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
    move::Tuple{Int64, Int64}
    parent::Nullable{Node}
    children::Vector{Node}
    wins::Int64
    visits::Int64
    untried_moves::Vector{Tuple{Int64, Int64}}
    just_moved::Int64
end

Node(move,parent,state) = Node(move,
                               parent,
                               Node[],
                               0,
                               0,
                               get_moves(state),
                               state.just_moved)
                               
function score(node, parent_visits)
  node.wins/node.visits + sqrt(2*log(parent_visits)/node.visits)
end

function uct_select_child(node)
    reduce(node.children) do a,b
      score(a, node.visits) > score(b, node.visits) ? a : b
    end
end

function add_child(node, move, state)
    n = Node(move, Nullable(node), state)
    deleteat!(node.untried_moves, findin(node.untried_moves, [move]))
    push!(node.children, n)
    n
end

function update(node, result)
    node.visits += 1
    node.wins += result
end

function uct(rootstate, itermax)
    rootnode = Node((0,0), Nullable(), rootstate)
    for i in 1:itermax
        node = rootnode
        state = clone(rootstate)

        while isempty(node.untried_moves) && !isempty(node.children)
            node = uct_select_child(node)
            make_move(state, node.move)
        end

        if !isempty(node.untried_moves)
            m = rand(node.untried_moves)
            make_move(state, m)
            node = add_child(node, m, state)
        end

        while !isempty(get_moves(state))
            make_move(state, rand(get_moves(state)))
        end

        while true
            update(node, get_result(state, node.just_moved))
            if isnull(node.parent)
               break
             end
            node = get(node.parent)
        end
    end
    
    best_node = reduce(rootnode.children) do a,b
      a.visits > b.visits ? a : b
    end
    best_node.move
end

function play_game(init)
    state = init
    println(state)
    while !isempty(get_moves(state))
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

for _ in 1:3
  srand(42)
  @time play_game(NimState(1, [10, 15]))
end

end
