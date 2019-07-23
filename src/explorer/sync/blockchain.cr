require "./../db/*"
require "./../node_api"

module Explorer
  module Sync
    class Blockchain
      # Initialize the chain at start
      def self.sync
        db_block_index = R.last_block_index
        node_block_index = NodeApi.last_block_index
        L.debug "DB last index: #{db_block_index.inspect}"
        L.debug "Node last index: #{node_block_index.inspect}"
        if db_block_index != node_block_index
          # Ensure to clean database if SushiChain node is on anoher chain or something is really bad !
          if node_block_index < db_block_index
            R.clean_tables
            db_block_index = 0
          end
          L.warn "Blockchain sync started..."
          Range.new(db_block_index, node_block_index).each do |iter|
            L.debug "Synchronizing block index #{iter}"
            block = NodeApi.block(iter.to_u64)
            L.debug "[Blockchain.sync] block to add: #{block}"
            R.add_block(block) if block
          end
          L.warn "Blockchain sync finished [#{(node_block_index - db_block_index) + 1} blocks added]..."
        else
          L.info "Blockchain is already synced..."
        end
      end

      # SushiChain live update from node websocket
      def self.event(ws_pubsub_url : String)
        @@socket = HTTP::WebSocket.new(URI.parse(ws_pubsub_url))

        socket.on_message do |message|
          L.debug "[Blockchain.event][raw message]: #{message}"
          block = Block.from_json(message)
          if block.not_nil!
            R.add_block(block)
            L.info "Block ##{block["index"]} added"
          end
        end

        socket.on_close do
          socket_close
        end

        L.info "Start listening block creation from SushiChain node websocket (#{ws_pubsub_url})..."
        spawn do
          socket.run
        rescue e : Exception
          L.error e.message.not_nil!
          socket_close
        end
      end

      private def self.socket
        @@socket.not_nil!
      end

      private def self.socket_close
        L.warn "SushiChain node socket closed"
        exit -42
      end
    end
  end
end
