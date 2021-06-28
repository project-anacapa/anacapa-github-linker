import React, { Component, Fragment } from 'react';
import * as PropTypes from 'prop-types';

import { PieChart } from 'react-chartkick'
import 'chartkick/chart.js'
import Papa from 'papaparse';

import DatePicker from "react-datepicker";
import "react-datepicker/dist/react-datepicker.css";

class CommitsAnalytics extends Component {

    constructor(props) {
        super(props);
        this.state = {commitData: undefined, startDate: startDate, endDate: endDate};
        const startDate = new Date();
        startDate.setDate(startDate.getDate() - 30);
        const endDate = new Date();
    }

    checkProperties(obj) {
        for (var key in obj) {
            if (obj[key] !== null && obj[key] != 0)
                return false;
        }
        return true;
    }

    componentDidMount() {
        this.getCommitData(this.props.team, undefined, undefined)
    }

    getCommitData = (team, startDate, endDate) => {
        var commitDataDict = {}

        for (const [key, value] of Object.entries(team.members)) {
            commitDataDict[value.full_name] = null
        }

        const response = fetch(`/courses/${team.org_team.course_id}/github_repos/${team.repos[0].repo.github_repo_id}/repo_commit_events.csv`).then(response => response.text().then(responseCSV => Papa.parse(responseCSV)))

        response.then(csv => {
            for (let i = 1; i < csv.data.length - 1; i++) {
                if (csv.data[i][11] in commitDataDict) {
                    if (startDate != undefined && endDate != undefined) {
                        if (csv.data[i][17] > startDate.toISOString() && csv.data[i][17] < endDate.toISOString()) {
                            commitDataDict[csv.data[i][11]] += parseInt(csv.data[i][15])
                            commitDataDict[csv.data[i][11]] += parseInt(csv.data[i][16])
                        }
                    } else {
                        commitDataDict[csv.data[i][11]] += parseInt(csv.data[i][15])
                        commitDataDict[csv.data[i][11]] += parseInt(csv.data[i][16])
                    }
                }
            }

            if (this.checkProperties(commitDataDict)) {
                commitDataDict = {}
            }

            this.setState({commitData: commitDataDict})
            
            console.log("commitDataDict", commitDataDict)
        })
    }

    onDateRangeChanged = (date, isStart) => {
        if (isStart) {
            this.setState({startDate: date});
        }
        else {
            this.setState({endDate: date});
        }
    }

    onButtonClick() {
        const startDate = this.state.startDate;
        const endDate = this.state.endDate;

        this.getCommitData(this.props.team, startDate, endDate)
        this.forceUpdate()
    }

    render() {
        const commitData = this.state.commitData;

        if (commitData == null) return "Loading...";
        
        return (
            <Fragment>
                <PieChart data={commitData} legend="bottom" width="500px" height="500px" empty="No Commits" />
                <div style={{ display: "flex", alignItems: "center", justifyContent: "center" }} >
                    <DatePicker
                        selected={this.state.startDate}
                        onChange={date => this.onDateRangeChanged(date, true)}
                        selectsStart
                        startDate={this.state.startDate}
                        endDate={this.state.endDate}
                    />
                    &nbsp;to&nbsp;
                    <DatePicker
                        style={{marginLeft: 10}}
                        selected={this.state.endDate}
                        onChange={date => this.onDateRangeChanged(date, false)}
                        selectsEnd
                        startDate={this.state.startDate}
                        endDate={this.state.endDate}
                        minDate={this.state.startDate}
                    />
                    <a onClick={() => this.onButtonClick()}>
                        <button>Get Commits</button>
                    </a>
                </div>
            </Fragment>
        );
    }
}

CommitsAnalytics.propTypes = {
    team: PropTypes.object.isRequired,
};

export default CommitsAnalytics;