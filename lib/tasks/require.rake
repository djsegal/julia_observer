namespace :require do

  desc "setup all dependencies"
  task all: :environment do
    Rake::Task["require:shallow"].invoke
    Rake::Task["require:deep"].invoke
  end

  desc "setup shallow dependencies"
  task shallow: :environment do
    ghost_packages = Set.new

    bar = make_progress_bar Package.current_batch_scope.count

    new_dependencies = []

    Package.current_batch_scope.all.each do |package|
      bar.inc

      Dependency.where(dependent: package).destroy_all

      package_directory = "#{@github_directory}/repos/#{package.name}"

      file_name = "#{package_directory}/require.yml"
      next unless File.exist? file_name

      require_file = YAML.load_file file_name
      next unless require_file.present?
      require_file = require_file['content']

      depended_packages = require_file.split("\n").reject &:blank?

      depended_packages.map! { |p| p.split.first }

      depended_packages.map! { |p| p.scan(/[^\/]*(?=\.jl)/).reject(&:blank?).first || p }

      depended_packages.uniq!

      depended_packages.each do |depended_name|
        next if depended_name.starts_with? '#'
        next if depended_name.starts_with? '@'

        unless Package.custom_exists? depended_name, batch_scope: "current_batch_scope"
          ghost_packages.add depended_name
          next
        end

        depended_package = \
          Package.custom_find depended_name, batch_scope: "current_batch_scope"

        new_dependencies << Dependency.new(
          is_shallow: true,
          dependent: package,
          depended: depended_package
        )
      end
    end

    Dependency.import new_dependencies, batch_size: 1000

    bar.finished

    puts ghost_packages.to_a.inspect
  end

  desc "setup deep dependencies"
  task deep: :environment do
    added_something_this_round = true
    added_something_this_sub_round = true

    while added_something_this_round

      added_something_this_round = false

      cur_package_list = Package.current_batch_scope.includes(:depending)

      while added_something_this_sub_round

        added_something_this_sub_round = false

        new_dependencies = []

        altered_packages = Set.new

        bar = make_progress_bar cur_package_list.count

        cur_package_list.each do |package|
          bar.inc

          package.depending.includes(:depending).each do |depended_package|
            deep_dependencies = depended_package.depending - package.depending
            next if deep_dependencies.empty?

            altered_packages.add package

            added_something_this_round = true
            added_something_this_sub_round = true

            deep_dependencies.each do |deep_dependency|
              new_dependencies << Dependency.new(
                is_shallow: false,
                dependent: package,
                depended: deep_dependency
              )
            end
          end
        end

        new_dependencies.uniq! { |cur_dependency| [ cur_dependency.dependent, cur_dependency.depended ] }

        Dependency.import new_dependencies, batch_size: 1000

        altered_packages.each { |cur_package| cur_package.reload }

        cur_package_list = altered_packages

        bar.finished

      end

    end

    dependencies = Dependency.arel_table

    circular_dependencies = Dependency
      .where(dependencies[:dependent_id]
      .eq(dependencies[:depended_id]))
      .map(&:dependent).map(&:name).uniq

    puts circular_dependencies.to_a.inspect
  end

end
