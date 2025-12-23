#!/usr/bin/env python3
"""
Cost estimation report generator for AWS ECS infrastructure.
Generates a detailed cost breakdown and recommendations.
"""

import json
import subprocess
import sys
from datetime import datetime
from typing import Dict, List


def run_infracost_breakdown() -> Dict:
    """Run infracost breakdown and return results."""
    try:
        result = subprocess.run(
            ["infracost", "breakdown", "--path", ".", "--format", "json"],
            capture_output=True,
            text=True,
            check=True
        )
        return json.loads(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"Error running infracost: {e}", file=sys.stderr)
        sys.exit(1)
    except FileNotFoundError:
        print("Infracost not found. Please install: https://www.infracost.io/docs/", file=sys.stderr)
        sys.exit(1)


def format_cost(cost: float) -> str:
    """Format cost with currency symbol."""
    return f"${cost:,.2f}"


def generate_report(data: Dict) -> str:
    """Generate formatted cost report."""
    report = []
    report.append("=" * 80)
    report.append("AWS ECS Infrastructure Cost Estimation Report")
    report.append(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    report.append("=" * 80)
    report.append("")

    # Summary
    total_monthly = data.get('totalMonthlyCost', 0)
    total_hourly = data.get('totalHourlyCost', 0)
    
    report.append("💰 COST SUMMARY")
    report.append("-" * 80)
    report.append(f"  Total Monthly Cost:  {format_cost(float(total_monthly))}")
    report.append(f"  Total Hourly Cost:   {format_cost(float(total_hourly))}")
    report.append(f"  Total Annual Cost:   {format_cost(float(total_monthly) * 12)}")
    report.append("")

    # Resource breakdown
    projects = data.get('projects', [])
    
    for project in projects:
        report.append(f"📊 PROJECT: {project.get('name', 'Unknown')}")
        report.append("-" * 80)
        
        breakdown = project.get('breakdown', {})
        resources = breakdown.get('resources', [])
        
        # Group by service
        services = {}
        for resource in resources:
            service = resource.get('name', '').split('.')[0]
            if service not in services:
                services[service] = {
                    'resources': [],
                    'total': 0.0
                }
            services[service]['resources'].append(resource)
            cost = float(resource.get('monthlyCost', 0))
            services[service]['total'] += cost
        
        # Display by service
        for service, info in sorted(services.items(), key=lambda x: x[1]['total'], reverse=True):
            report.append(f"\n  🔹 {service.upper()}")
            report.append(f"     Total: {format_cost(info['total'])}/month")
            
            for resource in info['resources']:
                name = resource.get('name', 'Unknown')
                cost = float(resource.get('monthlyCost', 0))
                report.append(f"     - {name}: {format_cost(cost)}/month")
        
        report.append("")

    # Cost optimization recommendations
    report.append("💡 COST OPTIMIZATION RECOMMENDATIONS")
    report.append("-" * 80)
    
    recommendations = [
        "1. Use Fargate Spot for non-critical workloads (up to 70% savings)",
        "2. Enable ECS Cluster Auto Scaling to match actual demand",
        "3. Use Reserved Instances or Savings Plans for predictable workloads",
        "4. Implement lifecycle policies for CloudWatch Logs retention",
        "5. Use S3 Intelligent-Tiering for terraform state storage",
        "6. Consider single NAT Gateway for dev environment",
        "7. Use CloudWatch Logs Insights to identify and remove verbose logging",
        "8. Implement tagging strategy for cost allocation",
        "9. Set up AWS Budgets for cost monitoring and alerts",
        "10. Regular review unused resources and rightsize instances"
    ]
    
    for rec in recommendations:
        report.append(f"  {rec}")
    
    report.append("")
    report.append("=" * 80)
    report.append("For detailed breakdown, run: infracost breakdown --path .")
    report.append("=" * 80)
    
    return "\n".join(report)


def save_report(report: str, filename: str = "cost-report.txt"):
    """Save report to file."""
    with open(filename, 'w') as f:
        f.write(report)
    print(f"Report saved to: {filename}")


def main():
    """Main function."""
    print("Generating cost estimation report...")
    data = run_infracost_breakdown()
    report = generate_report(data)
    print(report)
    save_report(report)


if __name__ == "__main__":
    main()
