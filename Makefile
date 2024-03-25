# Makefile for Ruby CLI Tool

# Define default make action
all: install

# Install dependencies using Bundler
install:
	@echo "Installing Ruby dependencies..."
	@gem install bundler
	@bundle install

# Run the Ruby script
run:
	@echo "Running the script..."
	ruby recentpedia.rb



# Help command to display available actions
help:
	@echo "Available commands:"
	@echo "  make install - Install Ruby dependencies using Bundler"
	@echo "  make run - Run the Ruby script"
	@echo "  make help - Display this help message"
