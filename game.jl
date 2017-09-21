module Game

mutable struct NimState
    just_moved::Int64
    chips::Vector{Int64}
end

function clone(state)
    NimState(state.just_moved, copy(state.chips))
end

function flip_player(state)
    state.just_moved = 1 - state.just_moved
end

function make_move(state, move)
    stack, count = move
    state.chips[stack] -= count
    flip_player(state)
    state
end

function get_moves(state)
    result = Tuple{Int64, Int64}[]
    for (stack, chips) in enumerate(state.chips)
        for count in 1:chips
            push!(result, (stack, count))
        end
    end
    result
end

function get_move(state, i)
    for (stack, chips) in enumerate(state.chips)
        if i > chips
            i -= chips
        else
            return (stack, i)
        end
    end
    error("This shouldn't happen")
end

function rand_move(state)
    total = sum(state.chips)
    i = rand(1:total)
    get_move(state, i)
end

@assert Set(get_moves(NimState(0, [1,2,3]))) == Set([rand_move(NimState(0, [1,2,3])) for i in 1:100])

function ended(state)
    all(state.chips) do (stack)
        stack == 0
    end
end

function get_result(state, just_moved)
    Int64(just_moved == state.just_moved)
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

function Node(move,parent,state) 
  moves = get_moves(state)
  shuffle!(moves)
  Node(move, parent, Node[], 0, 0, moves, state.just_moved)
end
                               
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
            m = pop!(node.untried_moves)
            make_move(state, m)
            node = add_child(node, m, state)
        end

        while !ended(state)
            make_move(state, rand_move(state))
        end

        while true
            update(node, get_result(state, node.just_moved))
            if isnull(node.parent)
               break
             end
            node = get(node.parent)
        end
        # if i > 10000
        #     best_node = reduce(rootnode.children) do a,b
        #         a.visits > b.visits ? a : b
        #     end
        #     if score(best_node, rootnode.visits) > 0.8
        #         println(score(best_node, get(best_node.parent).visits))
        #         return best_node
        #     end
        # end
    end
    
    best_node = reduce(rootnode.children) do a,b
      a.visits > b.visits ? a : b
    end
    best_node.move
end

function play_game(init)
    state = init
    println(state)
    while !ended(state)
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

for i in 1:5
    gc()
    @time begin
        # srand(42)
        init = NimState(1, [5, 30])
        move = uct(init, 1000000).move
        println(move)
        println(make_move(init, move))


    end
end

end
