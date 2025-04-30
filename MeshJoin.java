package warehouse;

import java.sql.*;
import java.util.*;

public class MeshJoin {
    private final Map<Integer, Double> productPriceMap = new HashMap<>(); // Stores product_id -> product_price mapping
    private final Map<Integer, String> customerNameMap = new HashMap<>(); // Stores customer_id -> customer_name mapping
    private static final int PARTITION_COUNT = 10; // Number of partitions to divide transactions into

    /**
     * Load master data (products and customers) into memory.
     * This allows quick lookup of product prices and customer names during transaction processing.
     */
    public void loadMasterData(Connection connection) {
        try (Statement stmt = connection.createStatement()) {
            // Load product details into memory
            System.out.println("Loading products into memory...");
            ResultSet products = stmt.executeQuery("SELECT product_id, product_price FROM products");
            while (products.next()) {
                int productId = products.getInt("product_id");
                double productPrice = products.getDouble("product_price");
                productPriceMap.put(productId, productPrice); // Map product_id to product_price
            }

            // Load customer details into memory
            System.out.println("Loading customers into memory...");
            ResultSet customers = stmt.executeQuery("SELECT customer_id, customer_name FROM customers");
            while (customers.next()) {
                int customerId = customers.getInt("customer_id");
                String customerName = customers.getString("customer_name");
                customerNameMap.put(customerId, customerName); // Map customer_id to customer_name
            }
        } catch (SQLException e) {
            System.err.println("Error loading master data: " + e.getMessage());
            e.printStackTrace();
        }
    }

    /**
     * Process transactions in the staging table and populate the sales_fact table.
     * Transactions are divided into partitions and processed in a stream-like manner.
     */
    public void processStreamData(Connection connection) {
        try (Statement stmt = connection.createStatement()) {
            // Determine the total number of transactions to calculate partition size
            ResultSet transactionCountResult = stmt.executeQuery("SELECT COUNT(*) AS total FROM transactions_staging");
            int totalTransactions = transactionCountResult.next() ? transactionCountResult.getInt("total") : 0;
            int partitionSize = (int) Math.ceil((double) totalTransactions / PARTITION_COUNT); // Size of each partition

            System.out.printf("Total Transactions: %d, Partition Size: %d%n", totalTransactions, partitionSize);

            // Process transactions partition by partition
            for (int partitionIndex = 0; partitionIndex < PARTITION_COUNT; partitionIndex++) {
                System.out.printf("Processing Partition (Stream Chunk) %d/%d%n", partitionIndex + 1, PARTITION_COUNT);

                // Fetch a single partition of transactions from the staging table
                String transactionQuery = String.format(
                        "SELECT order_id, order_date, product_id, customer_id, quantity_ordered " +
                        "FROM transactions_staging " +
                        "LIMIT %d OFFSET %d", // Limit and offset ensure only one partition is fetched
                        partitionSize, partitionIndex * partitionSize
                );

                try (ResultSet transactions = stmt.executeQuery(transactionQuery)) {
                    processPartition(transactions, connection, partitionIndex + 1); // Pass chunk/partition number
                }
            }
        } catch (SQLException e) {
            System.err.println("Error processing stream data: " + e.getMessage());
            e.printStackTrace();
        }
    }

    /**
     * Process a single partition of transactions.
     * Joins transactions with master data (products and customers) and inserts results into sales_fact.
     *
     * @param transactions  The result set containing transactions in the current partition.
     * @param connection    The database connection.
     * @param chunkNumber   The current chunk (stream) number being processed.
     */
    private void processPartition(ResultSet transactions, Connection connection, int chunkNumber) {
        String insertQuery = "INSERT INTO sales_fact (order_id, order_date, product_id, customer_id, quantity, product_price, total_sale) VALUES (?, ?, ?, ?, ?, ?, ?)";

        int transactionCount = 0; // Counter to track number of transactions processed in this partition

        try (PreparedStatement insertStmt = connection.prepareStatement(insertQuery)) {
            // Iterate through all transactions in the current partition
            while (transactions.next()) {
                int orderId = transactions.getInt("order_id");
                java.sql.Date orderDate = transactions.getDate("order_date"); // Transaction date
                int productId = transactions.getInt("product_id");
                int customerId = transactions.getInt("customer_id");
                int quantity = transactions.getInt("quantity_ordered");

                // Ensure product and customer data exist in memory
                if (!productPriceMap.containsKey(productId)) {
                    System.err.printf("No match found for Product ID: %d. Skipping transaction.%n", productId);
                    continue; // Skip transactions with invalid product_id
                }
                if (!customerNameMap.containsKey(customerId)) {
                    System.err.printf("No match found for Customer ID: %d. Skipping transaction.%n", customerId);
                    continue; // Skip transactions with invalid customer_id
                }

                // Calculate total sale for the transaction
                double productPrice = productPriceMap.get(productId); // Get product price from memory
                double totalSale = productPrice * quantity; // Calculate total sale

                System.out.printf("Stream %d - Processing Transaction %d: Order ID=%d, Total Sale=%.2f%n", 
                                  chunkNumber, ++transactionCount, orderId, totalSale);

                // Insert the processed transaction into the sales_fact table
                insertStmt.setInt(1, orderId);
                insertStmt.setDate(2, orderDate);
                insertStmt.setInt(3, productId);
                insertStmt.setInt(4, customerId);
                insertStmt.setInt(5, quantity);
                insertStmt.setDouble(6, productPrice);
                insertStmt.setDouble(7, totalSale);
                insertStmt.executeUpdate();
            }
        } catch (SQLException e) {
            System.err.println("Error processing partition: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
