class Graph
  def initialize
    @adjacency_list = {}
  end
  
  def add_edge(first_node, second_node)
    (@adjacency_list[first_node] ||= []) << second_node
    (@adjacency_list[second_node] ||= []) << first_node
    @adjacency_list
  end

  def size
    @adjacency_list.size
  end

  def all_nodes
    @adjacency_list.keys
  end

  def has_node?(node)
    @adjacency_list[node]
  end

  def dfs(first_node, visited = [])
    visited << first_node

    @adjacency_list[first_node]&.each do |node|
      self.dfs(node, visited) unless visited.include?(node) 
    end
    visited
  end
end