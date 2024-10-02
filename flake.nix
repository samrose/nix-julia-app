{
  description = "A complex Julia program for data analysis and visualization";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        juliaScript = pkgs.writeText "script.jl" ''
          using Pkg

          # Install required packages
          Pkg.add(["CSV", "DataFrames", "Plots", "StatsBase", "HTTP"])

          using CSV, DataFrames, Plots, StatsBase, HTTP

          # Download the Iris dataset
          url = "https://archive.ics.uci.edu/ml/machine-learning-databases/iris/iris.data"
          data = HTTP.get(url).body
          
          # Save the data to a local CSV file
          open("iris.csv", "w") do file
              write(file, data)
          end

          # Read the CSV file
          df = CSV.read("iris.csv", DataFrame, header=["sepal_length", "sepal_width", "petal_length", "petal_width", "species"])

          # Perform some basic analysis
          println("Summary Statistics:")
          println(describe(df))

          # Calculate correlation matrix
          numeric_df = select(df, Not(:species))
          cor_matrix = cor(Matrix(numeric_df))
          println("\nCorrelation Matrix:")
          println(cor_matrix)

          # Create a scatter plot
          p = scatter(df.sepal_length, df.sepal_width, group=df.species, 
                      title="Iris Dataset: Sepal Length vs Width", 
                      xlabel="Sepal Length", ylabel="Sepal Width")

          # Save the plot as a PNG file
          savefig(p, "iris_plot.png")

          println("\nAnalysis complete. Check 'iris_plot.png' for the visualization.")
        '';
        runScript = pkgs.writeShellScriptBin "run-julia-script" ''
          ${pkgs.julia}/bin/julia ${juliaScript}
        '';
      in
      {
        packages.default = runScript;
        apps.default = {
          type = "app";
          program = "${runScript}/bin/run-julia-script";
        };
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            julia
          ];
        };
      }
    );
}