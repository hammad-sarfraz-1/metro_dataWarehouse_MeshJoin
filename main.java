package warehouse;

import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.ResultSet;

public class main {
    public static void main(String[] args) {
        // Establish a connection to the database
        try (Connection databaseConnection = DatabaseConnection.getConnection()) {
            if (databaseConnection == null) {
                System.err.println("Failed to establish database connection. Exiting.");
                return; // Exit if connection is null
            }

            System.out.println("Database connection established.");

            // Create an instance of the MeshJoin class to handle ETL operations
            MeshJoin meshJoinHandler = new MeshJoin();

            // Step 1: Clear the sales_fact table before starting ETL
            try (Statement clearTableStatement = databaseConnection.createStatement()) {
                System.out.println("Clearing sales_fact table...");
                clearTableStatement.execute("TRUNCATE TABLE sales_fact"); // Clear previous data
            } catch (SQLException e) {
                System.err.println("Error occurred while clearing sales_fact table: " + e.getMessage());
                e.printStackTrace();
            }

            // Step 2: Load master data (products and customers) into memory
            meshJoinHandler.loadMasterData(databaseConnection);

            // Step 3: Process transaction data from transactions_staging and populate sales_fact
            meshJoinHandler.processStreamData(databaseConnection);

            // Step 4: Verify results in the sales_fact table
            try (Statement verificationStatement = databaseConnection.createStatement();
                 ResultSet resultSet = verificationStatement.executeQuery("SELECT COUNT(*) AS total FROM sales_fact")) {

                if (resultSet.next()) {
                    int totalRows = resultSet.getInt("total"); // Get total row count
                    System.out.println("Verification complete. Total rows in sales_fact: " + totalRows);
                }
            }
        } catch (SQLException e) {
            System.err.println("A database error occurred: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
