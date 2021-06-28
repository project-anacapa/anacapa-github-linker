import React, { Component, Fragment } from 'react';
import * as PropTypes from 'prop-types';

import { PieChart } from 'react-chartkick'
import 'chartkick/chart.js'

import {InputGroup, FormControl, Button} from "react-bootstrap";

import DatePicker from "react-datepicker";
import "react-datepicker/dist/react-datepicker.css";

class ChangeAnalytics extends Component {

    constructor(props) {
        super(props);
        this.state = {commitData: undefined, startDate: startDate, endDate: endDate, repoId: this.props.team.repos[0].repo.github_repo_id};
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

        const response = fetch(`/api/courses/${team.org_team.course_id}/github_repos/${this.state.repoId}/repo_commit_events`).then(response => response.json()).then(json => {
            console.log("json", json)
            for (let i = 1; i < json.length; i++) {
                if (json[i]["roster_student_id"] != null) {
                    var student_name = json[i]["roster_student"]["first_name"] + " " + json[i]["roster_student"]["last_name"]
                    if (student_name in commitDataDict) {
                        if (startDate != undefined && endDate != undefined) {
                            if (json[i]["commit_timestamp"] > startDate.toISOString() && json[i]["commit_timestamp"] < endDate.toISOString()) {
                                commitDataDict[student_name] += json[i]["additions"]
                                commitDataDict[student_name] += json[i]["deletions"]
                            }
                        } else {
                            commitDataDict[student_name] += json[i]["additions"]
                            commitDataDict[student_name] += json[i]["deletions"]
                        }
                    }
                }
            }

            if (this.checkProperties(commitDataDict)) {
                commitDataDict = {}
            }

            this.setState({commitData: commitDataDict})
        });
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

    onButtonClickGetRepo() {
        console.log("this.props", this.props)
        const response = fetch(`/api/courses/${this.props.course_id}/github_repos/`).then(response => response.json()).then(json => {
            for (const [key, repo] of Object.entries(json)) {
                if (repo["name"] == this.state.repoName) {
                    this.setState({repoId: repo["id"]})

                    this.getCommitData(this.props.team, this.state.startDate, this.state.endDate)
                    this.forceUpdate()
                }
            }
        });
    }

    render() {
        const commitData = this.state.commitData;

        if (commitData == null) return "Loading...";
        
        return (
            <Fragment>
                <div style={{ display: "flex", alignItems: "center", justifyContent: "flex-end", padding: "0px", margin: "0px" }}>
                    <InputGroup className="mb-3" className="w-25" style={{ paddingTop: "0px", marginTop: "0px" }}>
                        <FormControl
                        placeholder="Different repository?"
                        aria-label="Different repository?"
                        aria-describedby="basic-addon2"
                        onChange={e => this.setState({repoName: e.target.value})}
                        />
                        <InputGroup.Addon addon="append" style={{alignSelf: 'stretch', padding: "0px", margin: "0px"}}>
                            <Button variant="secondary" size="sm" style={{alignSelf: 'stretch', padding: ".5px", margin: "0px"}} onClick={() => this.onButtonClickGetRepo()}>Change Repo</Button>
                        </InputGroup.Addon>
                    </InputGroup>
                </div>
                <PieChart data={commitData} legend="bottom" width="500px" height="500px" empty="No Change" />
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
                        <button>Get Change</button>
                    </a>
                </div>
            </Fragment>
        );
    }
}

ChangeAnalytics.propTypes = {
    team: PropTypes.object.isRequired,
};

export default ChangeAnalytics;